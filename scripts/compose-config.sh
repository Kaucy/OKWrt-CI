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
kernel_profile="${9:?kernel profile is required}"

case "$platform:$subtarget:$kernel_profile" in
  qcom:ipq60xx:kernel-6m|qcom:ipq60xx:kernel-large|*:kernel-default) ;;
  *) echo "Invalid kernel profile for $platform/$subtarget: $kernel_profile" >&2; exit 1 ;;
esac

{
  printf 'CONFIG_TARGET_%s=y\n' "$target"
  printf 'CONFIG_TARGET_%s_%s=y\n' "$target" "$subtarget"
  # Device profiles live behind the target profile choice.  MULTI_PROFILE
  # exposes a separate TARGET_DEVICE_* namespace; using the single-profile
  # TARGET_<target>_<subtarget>_DEVICE_* symbols here would keep replacing the
  # choice and defconfig would silently retain only the last bundled device.
  printf 'CONFIG_TARGET_MULTI_PROFILE=y\n'
  for device in $devices; do
    printf 'CONFIG_TARGET_DEVICE_%s_%s_DEVICE_%s=y\n' "$target" "$subtarget" "$device"
  done
  cat "$GITHUB_WORKSPACE/config/common.config" \
    "$GITHUB_WORKSPACE/config/edition/$platform-$edition.config"
} > "$topdir/.config"

if [[ "$platform:$edition" == mtk:pro ]]; then
  case "$soc" in
    mt7981|mt7986)
      # Pro replaces mt76 with the closed mt_wifi stack. A small number of
      # upstream profiles still request mt76 modules/firmware directly, which
      # makes image assembly fail after those packages are disabled. The helper
      # also gives fixed sub-32 MiB images a compact Core package list; larger
      # profiles retain the complete common feature set.
      python3 "$GITHUB_WORKSPACE/scripts/prepare-mtk-pro-profiles.py" \
        "$topdir/target/linux/mediatek/image/filogic.mk"

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
      # with its feature guards. Apply the narrow source guard locally until
      # the maintained MTK fork carries the fix.
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

# Several IPQ60xx NOR/eMMC profiles have a real 6 MiB kernel partition.  BTF
# is required by daed in Standard and above, but the target's performance-
# optimized kernel plus BTF exceeds that immutable partition.  Optimize code
# size and drop diagnostics plus BTF-triggered facilities that daed does not
# use.  Keep vmlinux BTF, BPF events, kprobes/ftrace, cgroup BPF and the device
# KERNEL_SIZE unchanged.  Module symbol resolution uses the exported symbol
# table rather than CONFIG_KALLSYMS.  dae attaches at tc/cgroup hooks; it does
# not use netkit, sockmap stream parsing, module BTF or RDMA cgroups.  Keep XDP
# sockets enabled because the upstream daed package has a hard dependency on
# kmod-xdp-sockets-diag; disabling it makes defconfig silently drop daed and
# luci-app-daed from every Standard-capable image.
# Keep PERF_EVENTS and the ARM PMU drivers selected by KPROBES: overriding a
# selected OpenWrt Kconfig symbol leaves the generated Linux configuration
# incomplete.  MPTCP is optional and costs about 214 KiB compressed upstream,
# so omit it only from the immutable 6 MiB kernel profile.
# Keep every override in this target-only block so larger Qualcomm targets
# retain their upstream diagnostics and optional BPF facilities.
if [[ "$platform" == qcom && "$subtarget" == ipq60xx && "$kernel_profile" == kernel-6m && "$feature_set" != core ]]; then
  printf '%s\n' \
    '# CONFIG_KERNEL_CC_OPTIMIZE_FOR_PERFORMANCE is not set' \
    'CONFIG_KERNEL_CC_OPTIMIZE_FOR_SIZE=y' \
    '# CONFIG_KERNEL_KALLSYMS is not set' \
    '# CONFIG_KERNEL_DEBUG_FS is not set' \
    '# CONFIG_KERNEL_DEBUG_INFO_BTF_MODULES is not set' \
    '# CONFIG_KERNEL_MODULE_ALLOW_BTF_MISMATCH is not set' \
    '# CONFIG_KERNEL_CGROUP_RDMA is not set' \
    '# CONFIG_KERNEL_ARM64_BRBE is not set' \
    '# CONFIG_KERNEL_BPF_STREAM_PARSER is not set' \
    '# CONFIG_KERNEL_NETKIT is not set' \
    '# CONFIG_KERNEL_MPTCP is not set' \
    '# CONFIG_KERNEL_MPTCP_IPV6 is not set' \
    '# CONFIG_KERNEL_MAGIC_SYSRQ is not set' \
    '# CONFIG_KERNEL_ELF_CORE is not set' >> "$topdir/.config"
fi

# Qualcomm's Linux 6.12 target fragment force-enables process/device core dumps
# and verbose BUG file/line strings after the top-level compact profile is
# composed.  They are post-mortem diagnostics, are not used by daed's BPF/XDP
# path, and account for the remaining small overrun on immutable 6 MiB profiles.
# Override the Linux fragments only in the kernel-6m job; kernel-large runs in
# a separate source tree and retains the upstream coredump facilities.
if [[ "$platform" == qcom && "$subtarget" == ipq60xx && "$kernel_profile" == kernel-6m ]]; then
  while IFS= read -r kernel_fragment; do
    sed -i \
      -e '/^CONFIG_ALLOW_DEV_COREDUMP=/d' \
      -e '/^# CONFIG_ALLOW_DEV_COREDUMP is not set$/d' \
      -e '/^CONFIG_COREDUMP=/d' \
      -e '/^# CONFIG_COREDUMP is not set$/d' \
      -e '/^CONFIG_DEV_COREDUMP=/d' \
      -e '/^# CONFIG_DEV_COREDUMP is not set$/d' \
      -e '/^CONFIG_DEBUG_BUGVERBOSE=/d' \
      -e '/^# CONFIG_DEBUG_BUGVERBOSE is not set$/d' \
      "$kernel_fragment"
    printf '%s\n' \
      '# CONFIG_ALLOW_DEV_COREDUMP is not set' \
      '# CONFIG_COREDUMP is not set' \
      '# CONFIG_DEV_COREDUMP is not set' \
      '# CONFIG_DEBUG_BUGVERBOSE is not set' >> "$kernel_fragment"
  done < <(find \
    "$topdir/target/linux/$target" \
    "$topdir/target/linux/$target/$subtarget" \
    -maxdepth 1 -type f \( -name 'config-*' -o -name 'config-default' \) \
    -print 2>/dev/null | sort -u)
fi

# LibWrt 的 QCA NSS 补丁新增了一个没有 OpenWrt 顶层 CONFIG_KERNEL_ 映射的
# 内核选项。它只属于 Qualcomm Pro；Qualcomm Open 使用 ImmortalWrt 源码树。
if [[ "$platform" == qcom && "$target" == qualcommax && "$edition" == pro ]]; then
  kernel_config="$topdir/target/linux/$target/$subtarget/config-default"
  sed -i '/^#\? *CONFIG_NF_CONNTRACK_DSCPREMARK_EXT/d' "$kernel_config"
  printf '%s\n' 'CONFIG_NF_CONNTRACK_DSCPREMARK_EXT=y' >> "$kernel_config"
fi
