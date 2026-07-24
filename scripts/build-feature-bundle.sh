#!/usr/bin/env bash
set -euo pipefail

topdir="${1:?OpenWrt source directory is required}"
platform="${2:?platform is required}"
target="${3:?target is required}"
subtarget="${4:?subtarget is required}"
edition="${5:?edition is required}"
channel="${6:?channel is required}"
devices="${7:?device list is required}"
soc="${8:-all}"
kernel_profile="${9:?kernel profile is required}"
chunk="${10:?chunk is required}"
scope="${11:-all}"

case "$platform:$subtarget:$kernel_profile" in
  qcom:ipq60xx:kernel-6m|qcom:ipq60xx:kernel-large|*:kernel-default) ;;
  *) echo "Invalid kernel profile for $platform/$subtarget: $kernel_profile" >&2; exit 1 ;;
esac
case "$scope" in
  all|smoke) ;;
  *) echo "Invalid build scope: $scope" >&2; exit 1 ;;
esac

catalog="$GITHUB_WORKSPACE/config/devices.tsv"
upload="$GITHUB_WORKSPACE/upload"
failures="$GITHUB_WORKSPACE/.build-failures"
features=(core standard standard-usb ultra)
declare -A ranks=([core]=0 [standard]=1 [standard-usb]=2 [ultra]=3)
declare -A maximum=()

reclaim_variant_space() {
  # 功能集之间只清理可重新生成的文件；保留工具链、主机工具和包编译结果，
  # 同时确保下一个功能集以及最终 artifact 上传始终有可用空间。
  rm -rf "$topdir/bin/packages" "$topdir/dl/go-mod-cache"
  find "$topdir/build_dir" "$topdir/staging_dir" -mindepth 1 -maxdepth 3 \
    -type d -name 'root-*' -prune -exec rm -rf {} + 2>/dev/null || true
  CCACHE_DIR="$topdir/.ccache" ccache --cleanup >/dev/null 2>&1 || true
  df -h "$topdir"
}

: > "$failures"
mkdir -p "$upload"

while IFS=$'\t' read -r row_platform row_target row_subtarget device _name _soc row_edition row_channel max_feature row_kernel_profile; do
  [[ "$row_platform" == platform ]] && continue
  [[ "$row_platform:$row_target:$row_subtarget:$row_edition:$row_channel" == "$platform:$target:$subtarget:$edition:$channel" ]] || continue
  for requested in $devices; do
    [[ "$device" == "$requested" && "$row_kernel_profile" == "$kernel_profile" ]] && maximum["$device"]="$max_feature"
  done
done < "$catalog"

highest=core
for device in $devices; do
  [[ -n "${maximum[$device]:-}" ]] || { echo "Device is missing from catalog: $device" >&2; exit 1; }
  (( ranks[${maximum[$device]}] > ranks[$highest] )) && highest="${maximum[$device]}"
done

# 安装本分块最高功能集需要的包一次，后续各功能集复用同一源码树和编译缓存。
setup_log="$GITHUB_WORKSPACE/setup.log"
set +e
(
  set -euo pipefail
  "$GITHUB_WORKSPACE/scripts/install-packages.sh" "$topdir" "$highest"
  "$GITHUB_WORKSPACE/scripts/apply-branding.sh" "$topdir"
) 2>&1 | tee "$setup_log"
setup_status=${PIPESTATUS[0]}
set -e
if ((setup_status != 0)); then
  mkdir -p "$upload/setup-failure"
  mv "$setup_log" "$upload/setup-failure/build-failure.log"
  echo setup-failure > "$failures"
  exit "$setup_status"
fi
rm -f "$setup_log"

# OpenWrt 默认允许 ccache 持续增长；多功能集顺序构建时必须严格设限，
# 并立即裁剪 Actions 恢复的旧缓存。否则首个 Ultra 变种还没结束，缓存
# 与完整工具链就可能耗尽 runner 根分区，连 Actions 自身日志都无法写入。
CCACHE_DIR="$topdir/.ccache" ccache --max-size=1G
CCACHE_DIR="$topdir/.ccache" ccache --cleanup

# 先构建最高功能集，使内核模块全集一次生成。OpenWrt 的内核编译 stamp
# 不会因为后续功能集新增 kmod 自动失效；从 Core 向上构建会出现模块已被
# 选中但对应 .ko 尚未生成（例如 sha256-arm64.ko）的假性缺失。
for ((feature_index=${#features[@]} - 1; feature_index >= 0; feature_index--)); do
  feature="${features[$feature_index]}"
  # Smoke is a representative integration test, not a second full matrix.
  # The highest eligible feature includes every lower feature's packages and
  # exercises the widest kernel/package dependency path.  Build only that
  # feature here; scope=all still builds every eligible feature for release.
  [[ "$scope" == all || "$feature" == "$highest" ]] || continue
  selected=()
  for device in $devices; do
    (( ranks[$feature] <= ranks[${maximum[$device]}] )) && selected+=("$device")
  done
  ((${#selected[@]})) || continue

  device_list="${selected[*]}"
  variant="$target-$subtarget-$edition-$channel"
  [[ "$soc" == all ]] || variant+="-$soc"
  [[ "$subtarget" == ipq60xx ]] && variant+="-$kernel_profile"
  variant+="-$feature-part$chunk"
  out="$upload/$variant"
  log="$GITHUB_WORKSPACE/$variant.log"
  mkdir -p "$out"

  echo "::group::Build $variant ($device_list)"
  set +e
  (
    set -euo pipefail
    "$GITHUB_WORKSPACE/scripts/compose-config.sh" "$topdir" \
      "$platform" "$target" "$subtarget" "$edition" "$feature" "$device_list" "$soc" "$kernel_profile"
    cd "$topdir"
    make defconfig
    for device in $device_list; do
      grep -Fq "_DEVICE_${device}=y" .config || {
        echo "Expected device profile was not selected: $device" >&2
        exit 1
      }
    done
    cp .config "$out/config.txt"
    make download -j8
    find dl -type f -size -1024c -print -delete
    if [[ "$feature" != core ]]; then
      # Some upstream feature transitions remove the staged GNU sed wrapper
      # while retaining host-package stamps. Lua's host build then tries the
      # missing path and daed fails before compiling. The system GNU sed is
      # compatible with the staged tool contract, so restore the path when
      # necessary instead of rebuilding the complete host toolchain.
      if [[ ! -x staging_dir/host/bin/sed ]]; then
        mkdir -p staging_dir/host/bin
        ln -s /usr/bin/sed staging_dir/host/bin/sed
      fi
      # Actions caches can also retain host-tool stamps after Meson's staged
      # templates were removed. Reinstall that small host tool atomically;
      # copying only the currently missing template would leave the cache in
      # an unknown state and can fail again on the next Meson consumer.
      if [[ ! -f staging_dir/host/bin/meson.py \
         || ! -f staging_dir/host/lib/meson/openwrt-native.txt.in \
         || ! -f staging_dir/host/lib/meson/openwrt-cross.txt.in ]]; then
        make tools/meson/clean
        make tools/meson/compile -j1 V=s
      fi
      # APK key generation runs before the normal world build has populated
      # host/bin.  The runner OpenSSL implements the required ec/ecparam CLI,
      # so stage it just like GNU sed when the cached path is absent.
      if [[ ! -x staging_dir/host/bin/openssl ]]; then
        mkdir -p staging_dir/host/bin
        ln -s /usr/bin/openssl staging_dir/host/bin/openssl
      fi
    fi
    target_dir="$topdir/bin/targets/$target/$subtarget"
    rm -rf "$target_dir"
    if ! make -j"$(nproc)"; then
      recovery_attempted=false
      if [[ "$feature" != core ]]; then
        # world 会先准备完整工具链；只有它失败后才串行重试 daed，避免
        # 在 libgcc、Ninja 等依赖尚未生成时把诊断构建本身变成故障源。
        make package/feeds/packages/daed/compile -j1 V=s
        recovery_attempted=true
      fi
      if [[ "$platform:$edition" == "mtk:pro" ]]; then
        # 厂商驱动可能在失败前写入 .built；先清理依赖链，再串行重建，
        # 否则重试会直接进入打包并误报 mt_wifi.ko 缺失。
        make package/mtk/drivers/warp/clean
        make package/mtk/drivers/mt_wifi/clean
        make package/mtk/drivers/conninfra/clean
        make package/mtk/drivers/conninfra/compile -j1 V=s
        make package/mtk/drivers/mt_wifi/compile -j1 V=s
        make package/mtk/drivers/warp/compile -j1 V=s
        recovery_attempted=true
      fi
      if [[ "$platform:$edition" == "qcom:pro" ]]; then
        # qca-nss-ecm changes its kernel feature set between bundles.  Remove
        # stale package stamps and rebuild it serially before retrying world;
        # this also preserves the actionable compiler output on a real error.
        make package/feeds/nss_packages/qca-nss-ecm/clean
        make package/feeds/nss_packages/qca-nss-ecm/compile -j1 V=s
        recovery_attempted=true
      fi
      $recovery_attempted || exit 1
      # A second parallel world build hides APK/rootfs installation failures
      # behind the generic top-level error. Most outputs are already built at
      # this point, so finish serially with verbose output: this also removes
      # package/install races and preserves the first actionable error.
      # Keep this as the last recovery step so its log remains authoritative.
      make -j1 V=s
    fi

    test -d "$target_dir"
    find "$target_dir" -maxdepth 1 -type f -exec cp {} "$out/" \;
    # Initramfs images are recovery/boot diagnostics, not installable firmware.
    # Keeping them beside the real images can make a single Ultra artifact
    # exceed the independent-download limit without adding a release asset.
    # Remove them before generating the authoritative artifact checksum list.
    find "$out" -maxdepth 1 -type f -iname '*initramfs*' -delete
    if [[ "$feature" != core ]]; then
      shopt -s nullglob
      manifests=("$out"/*.manifest)
      shopt -u nullglob
      ((${#manifests[@]})) || {
        echo "No package manifest was produced for $variant" >&2
        exit 1
      }
      for package in \
        luci-app-homeproxy luci-app-passwall2 \
        luci-app-daed daed daed-geoip daed-geosite \
        sing-box xray-core v2ray-geoip v2ray-geosite; do
        grep -hEq "^${package} - " "${manifests[@]}" || {
          echo "Required Standard package is missing from $variant: $package" >&2
          exit 1
        }
      done
    fi
    # profiles.json is authoritative for a multi-profile build.  Checking only
    # that the directory contains one firmware lets a silently skipped device
    # hide behind another successful device in the same chunk.
    "$GITHUB_WORKSPACE/scripts/verify-build-output.sh" "$out" $device_list
  ) 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  set -e
  echo "::endgroup::"

  reclaim_variant_space

  if ((status != 0)); then
    printf '%s\n' "$variant" >> "$failures"
    mv "$log" "$out/build-failure.log"
    continue
  fi
  rm -f "$log"

  # Upstream targets ship a lowercase sha256sums file. GitHub artifact paths
  # are case-insensitive, so keeping it beside our authoritative SHA256SUMS
  # causes an upload collision even though Linux accepts both names.
  rm -f "$out/sha256sums" "$out/SHA256SUMS"

  printf '%s\n' \
    "variant=$variant" \
    "platform=$platform" \
    "target=$target" \
    "subtarget=$subtarget" \
    "edition=$edition" \
    "channel=$channel" \
    "feature_set=$feature" \
    "soc=$soc" \
    "kernel_profile=$kernel_profile" \
    "build_scope=$scope" \
    "chunk=$chunk" \
    "fork_sha=$FORK_SHA" \
    "upstream_sha=$UPSTREAM_SHA" \
    "source_branch=$SOURCE_BRANCH" \
    "devices=$device_list" \
    "management_ip=$OKWRT_IP" \
    "username=$OKWRT_USER" > "$out/build-metadata.txt"
  (cd "$out" && sha256sum -- * > SHA256SUMS)
done

if [[ -s "$failures" ]]; then
  echo "Failed variants:" >&2
  cat "$failures" >&2
fi
