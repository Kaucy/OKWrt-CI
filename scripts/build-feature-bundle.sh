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
chunk="${9:?chunk is required}"

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

while IFS=$'\t' read -r row_platform row_target row_subtarget device _name _soc row_edition row_channel max_feature; do
  [[ "$row_platform" == platform ]] && continue
  [[ "$row_platform:$row_target:$row_subtarget:$row_edition:$row_channel" == "$platform:$target:$subtarget:$edition:$channel" ]] || continue
  for requested in $devices; do
    [[ "$device" == "$requested" ]] && maximum["$device"]="$max_feature"
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

# OpenWrt 默认允许 ccache 持续增长；多功能集顺序构建时必须设上限，避免
# 调试信息/BTF 变化产生的两套对象占满 GitHub runner。
CCACHE_DIR="$topdir/.ccache" ccache --max-size=5G

# 先构建最高功能集，使内核模块全集一次生成。OpenWrt 的内核编译 stamp
# 不会因为后续功能集新增 kmod 自动失效；从 Core 向上构建会出现模块已被
# 选中但对应 .ko 尚未生成（例如 sha256-arm64.ko）的假性缺失。
for ((feature_index=${#features[@]} - 1; feature_index >= 0; feature_index--)); do
  feature="${features[$feature_index]}"
  selected=()
  for device in $devices; do
    (( ranks[$feature] <= ranks[${maximum[$device]}] )) && selected+=("$device")
  done
  ((${#selected[@]})) || continue

  device_list="${selected[*]}"
  variant="$target-$subtarget-$edition-$channel"
  [[ "$soc" == all ]] || variant+="-$soc"
  variant+="-$feature-part$chunk"
  out="$upload/$variant"
  log="$GITHUB_WORKSPACE/$variant.log"
  mkdir -p "$out"

  echo "::group::Build $variant ($device_list)"
  set +e
  (
    set -euo pipefail
    "$GITHUB_WORKSPACE/scripts/compose-config.sh" "$topdir" \
      "$platform" "$target" "$subtarget" "$edition" "$feature" "$device_list" "$soc"
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
      # daed 的 Go/eBPF/前端构建错误在并行 world 日志中只显示一行摘要。
      # 先单独构建可得到完整错误，并让后续 world 直接复用成功结果。
      make package/feeds/packages/daed/compile -j1 V=s
    fi
    target_dir="$topdir/bin/targets/$target/$subtarget"
    rm -rf "$target_dir"
    if ! make -j"$(nproc)"; then
      if [[ "$platform:$edition" == "mtk:pro" ]]; then
        # 完整构建已生成 host 工具；此时再串行重试厂商底层驱动，既可
        # 输出明确错误，也能修复部分厂商 Makefile 的并行竞态。
        make package/mtk/drivers/conninfra/compile -j1 V=s
        make package/mtk/drivers/warp/compile -j1 V=s
        make -j"$(nproc)"
      else
        exit 1
      fi
    fi

    test -d "$target_dir"
    find "$target_dir" -maxdepth 1 -type f -exec cp {} "$out/" \;
    # 只有真正可刷写的 factory/sysupgrade/combined 镜像才算固件；
    # kernel.bin、initramfs、preloader 等辅助文件不能让完整性检查误通过。
    find "$out" -maxdepth 1 -type f \
      \( -name '*-sysupgrade.bin' -o -name '*-factory.bin' \
         -o -name '*-sysupgrade.itb' -o -name '*-factory.itb' \
         -o -name '*-sysupgrade.ubi' -o -name '*-factory.ubi' \
         -o -name '*-combined*.img.gz' \) \
      -print -quit | grep -q .
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

  printf '%s\n' \
    "variant=$variant" \
    "platform=$platform" \
    "target=$target" \
    "subtarget=$subtarget" \
    "edition=$edition" \
    "channel=$channel" \
    "feature_set=$feature" \
    "soc=$soc" \
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
