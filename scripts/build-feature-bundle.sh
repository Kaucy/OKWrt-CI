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
"$GITHUB_WORKSPACE/scripts/install-packages.sh" "$topdir" "$highest"
"$GITHUB_WORKSPACE/scripts/apply-branding.sh" "$topdir"

for feature in "${features[@]}"; do
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
    target_dir="$topdir/bin/targets/$target/$subtarget"
    rm -rf "$target_dir"
    make -j"$(nproc)" || make -j1 V=s

    test -d "$target_dir"
    find "$target_dir" -maxdepth 1 -type f -exec cp {} "$out/" \;
    find "$out" -maxdepth 1 -type f \
      \( -name '*.bin' -o -name '*.itb' -o -name '*.ubi' -o -name '*.img.gz' \) \
      -print -quit | grep -q .
  ) 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  set -e
  echo "::endgroup::"

  if ((status != 0)); then
    printf '%s\n' "$variant" >> "$failures"
    mv "$log" "$out/build-failure.log"
    continue
  fi
  rm -f "$log"

  printf '%s\n' \
    "variant=$variant" \
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
