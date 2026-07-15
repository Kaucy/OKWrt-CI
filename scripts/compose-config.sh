#!/usr/bin/env bash
set -euo pipefail

topdir="${1:?OpenWrt source directory is required}"
platform="${2:?platform is required}"
target="${3:?target is required}"
subtarget="${4:?subtarget is required}"
edition="${5:?edition is required}"
feature_set="${6:?feature set is required}"
devices="${7:?device list is required}"
soc="${8:-all}"

{
  printf 'CONFIG_TARGET_%s=y\n' "$target"
  printf 'CONFIG_TARGET_%s_%s=y\n' "$target" "$subtarget"
  for device in $devices; do
    printf 'CONFIG_TARGET_%s_%s_DEVICE_%s=y\n' "$target" "$subtarget" "$device"
  done
  cat "$GITHUB_WORKSPACE/config/common.config" \
    "$GITHUB_WORKSPACE/config/edition/$platform-$edition.config"
} > "$topdir/.config"

if [[ "$platform:$edition" == mtk:pro ]]; then
  case "$soc" in
    mt7981|mt7986)
      # mt_wifi depends on the vendor conninfra module.  The package does not
      # infer its APSOC implementation from CONFIG_MTK_CHIP_*, so leaving this
      # choice unset builds conninfra.ko without the platform OF match table
      # (apconninfra_of_ids) and fails at modpost.
      printf '%s\n' \
        "CONFIG_MTK_CHIP_${soc^^}=y" \
        'CONFIG_MTK_CONNINFRA_APSOC=y' \
        "CONFIG_MTK_CONNINFRA_APSOC_${soc^^}=y" >> "$topdir/.config"
      ;;
    *) echo "Unsupported MediaTek Pro SoC: $soc" >&2; exit 1 ;;
  esac
fi

case "$feature_set" in
  core)
    ;;
  standard)
    cat "$GITHUB_WORKSPACE/config/features/standard.config" >> "$topdir/.config"
    ;;
  standard-usb)
    cat "$GITHUB_WORKSPACE/config/features/standard.config" \
        "$GITHUB_WORKSPACE/config/features/standard-usb.config" >> "$topdir/.config"
    ;;
  ultra)
    cat "$GITHUB_WORKSPACE/config/features/standard.config" \
        "$GITHUB_WORKSPACE/config/features/standard-usb.config" \
        "$GITHUB_WORKSPACE/config/features/ultra.config" >> "$topdir/.config"
    ;;
  *)
    echo "Unknown feature set: $feature_set" >&2
    exit 1
    ;;
esac

# LibWrt 的 QCA NSS 补丁新增了一个没有 OpenWrt 顶层 CONFIG_KERNEL_ 映射的
# 内核选项。它只属于 Qualcomm Pro；Qualcomm Open 使用 ImmortalWrt 源码树。
if [[ "$platform" == qcom && "$target" == qualcommax && "$edition" == pro ]]; then
  kernel_config="$topdir/target/linux/$target/$subtarget/config-default"
  sed -i '/^#\? *CONFIG_NF_CONNTRACK_DSCPREMARK_EXT/d' "$kernel_config"
  printf '%s\n' 'CONFIG_NF_CONNTRACK_DSCPREMARK_EXT=y' >> "$kernel_config"
fi
