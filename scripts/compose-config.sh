#!/usr/bin/env bash
set -euo pipefail

topdir="${1:?OpenWrt source directory is required}"
platform="${2:?platform is required}"
edition="${3:?edition is required}"
feature_set="${4:?feature set is required}"

cat "$GITHUB_WORKSPACE/config/platform/$platform.config" \
    "$GITHUB_WORKSPACE/config/common.config" \
    "$GITHUB_WORKSPACE/config/edition/$platform-$edition.config" \
    > "$topdir/.config"

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
if [[ "$platform" == qcom && "$edition" == pro ]]; then
  kernel_config="$topdir/target/linux/qualcommax/ipq60xx/config-default"
  sed -i '/^#\? *CONFIG_NF_CONNTRACK_DSCPREMARK_EXT/d' "$kernel_config"
  printf '%s\n' 'CONFIG_NF_CONNTRACK_DSCPREMARK_EXT=y' >> "$kernel_config"
fi
