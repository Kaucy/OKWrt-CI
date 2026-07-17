#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
bundle="$root/scripts/build-feature-bundle.sh"
compose="$root/scripts/compose-config.sh"
install_packages="$root/scripts/install-packages.sh"
mtk_config="$root/config/edition/mtk-pro.config"
standard_config="$root/config/features/standard.config"
standard_usb_config="$root/config/features/standard-usb.config"
mtk_ap_patch="$root/patches/mtk/041-mt-wifi-ap-only-sae-guards.patch"

# Keep the smoke checks cheap: these assertions cover the three CI regressions
# before a multi-hour firmware build is started.
grep -Fq 'ln -s /usr/bin/sed staging_dir/host/bin/sed' "$bundle"
grep -Fq 'make tools/meson/clean' "$bundle"
grep -Fq 'make tools/meson/compile -j1 V=s' "$bundle"
grep -Fq "printf 'CONFIG_TARGET_MULTI_PROFILE=y" "$compose"
grep -Fq 'ln -s /usr/bin/openssl staging_dir/host/bin/openssl' "$bundle"
grep -Fq '041-mt-wifi-ap-only-sae-guards.patch' "$compose"
grep -Fq '#if defined(DOT11_SAE_SUPPORT) || defined(SUPP_SAE_SUPPORT)' "$mtk_ap_patch"
grep -Fq 'struct _RTMP_ADAPTER *pAd = (struct _RTMP_ADAPTER *)wdev->sys_handle;' "$mtk_ap_patch"
grep -Fq "s/+python3-pkg-resources[[:space:]]*//" "$install_packages"
grep -Fq "s/+python3-email[[:space:]]*//" "$install_packages"
grep -Fxq 'CONFIG_PACKAGE_luci-app-daed=y' "$standard_config"
grep -Fxq 'CONFIG_PACKAGE_daed=y' "$standard_config"
grep -Fxq 'CONFIG_KERNEL_DEBUG_INFO_BTF=y' "$standard_config"
grep -Fxq 'CONFIG_KERNEL_BPF_EVENTS=y' "$standard_config"
grep -Fq 'make package/feeds/packages/daed/compile -j1 V=s' "$bundle"
grep -Fq 'make package/mtk/drivers/mt_wifi/clean' "$bundle"
grep -Fq 'make package/mtk/drivers/mt_wifi/compile -j1 V=s' "$bundle"
grep -Fq 'make package/feeds/nss_packages/qca-nss-ecm/clean' "$bundle"
grep -Fq 'make package/feeds/nss_packages/qca-nss-ecm/compile -j1 V=s' "$bundle"
# The post-recovery world run must expose package/install diagnostics.
grep -Fq 'make -j1 V=s' "$bundle"
grep -Fq 'CCACHE_DIR="$topdir/.ccache" ccache --max-size=1G' "$bundle"
grep -Fq 'CCACHE_DIR="$topdir/.ccache" ccache --cleanup' "$bundle"
grep -Fq 'rm -f "$out/sha256sums" "$out/SHA256SUMS"' "$bundle"
grep -Fxq 'CONFIG_MTK_MT_WIFI=m' "$mtk_config"
grep -Fxq 'CONFIG_MTK_WIFI_MODE_AP=m' "$mtk_config"
grep -Fxq 'CONFIG_MTK_MT_AP_SUPPORT=m' "$mtk_config"
grep -Fxq 'CONFIG_MTK_DOT11K_RRM_SUPPORT=y' "$mtk_config"
grep -Fxq '# CONFIG_MTK_APCLI_SUPPORT is not set' "$mtk_config"
grep -Fxq '# CONFIG_MTK_WPA3_SUPPORT is not set' "$mtk_config"
! grep -Fxq 'CONFIG_MTK_WPA3_SUPPORT=y' "$mtk_config"
grep -Fxq 'CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_generic-qmi-wwan=y' "$standard_usb_config"
grep -Fxq '# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_vendor-qmi-wwan is not set' "$standard_usb_config"
grep -Fxq '# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_nss-qmi-wwan is not set' "$standard_usb_config"
grep -Fxq 'CONFIG_PACKAGE_kmod-ipt-nat=y' "$mtk_config"

world_line="$(grep -nF 'if ! make -j"$(nproc)"; then' "$bundle" | cut -d: -f1)"
daed_line="$(grep -nF 'make package/feeds/packages/daed/compile -j1 V=s' "$bundle" | cut -d: -f1)"
((daed_line > world_line)) || {
  echo 'daed retry must run after the first world build' >&2
  exit 1
}

echo 'Build bundle regression checks passed.'
