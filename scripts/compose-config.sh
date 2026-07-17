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
  # Device profiles live behind the target profile choice.  Without selecting
  # MULTI_PROFILE, every DEVICE_=y line replaces the previous choice and
  # defconfig silently keeps only the last device in a bundle.
  printf 'CONFIG_TARGET_MULTI_PROFILE=y\n'
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
        '# CONFIG_MTK_FIRST_IF_NONE is not set' \
        "CONFIG_MTK_FIRST_IF_${soc^^}=y" \
        'CONFIG_MTK_SECOND_IF_NONE=y' \
        'CONFIG_MTK_THIRD_IF_NONE=y' \
        'CONFIG_MTK_CONNINFRA_APSOC=y' \
        "CONFIG_MTK_CONNINFRA_APSOC_${soc^^}=y" \
        'CONFIG_WARP_VERSION=2' \
        "CONFIG_WARP_CHIPSET=\"$soc\"" >> "$topdir/.config"

      # 上游 WARP 只在识别到内核 HNAT 宏时编译 tuple helpers，但 OpenWrt
      # 将 HNAT 作为 kmod 构建时，该宏没有传入厂商外部模块的编译环境。
      # WARP 已硬依赖 kmod-mediatek_hnat，故在厂商模块内显式声明是安全的。
      install -m 0644 \
        "$GITHUB_WORKSPACE/patches/mtk/010-warp-openwrt-hnat-module.patch" \
        "$topdir/package/mtk/drivers/warp/patches/010-warp-openwrt-hnat-module.patch"
      # mt_wifi 7.6.7.3 leaves an SAE call and pAd declaration inconsistent
      # with its AP-only Kconfig path. Apply the narrow source guard locally
      # until the maintained MTK fork carries the fix.
      install -m 0644 \
        "$GITHUB_WORKSPACE/patches/mtk/041-mt-wifi-ap-only-sae-guards.patch" \
        "$topdir/package/mtk/drivers/mt_wifi/patches-7673/041-mt-wifi-ap-only-sae-guards.patch"
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
