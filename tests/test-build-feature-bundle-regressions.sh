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
shard_workflow="$root/.github/workflows/_build-shard.yml"

for workflow in \
  "$root/.github/workflows/build.yml" \
  "$root/.github/workflows/build-qcom-pro.yml" \
  "$root/.github/workflows/build-mtk-open.yml" \
  "$root/.github/workflows/build-mtk-pro.yml"; do
  grep -Fq -- "- 'patches/**'" "$workflow"
done

# Keep the smoke checks cheap: these assertions cover the three CI regressions
# before a multi-hour firmware build is started.
grep -Fq 'ln -s /usr/bin/sed staging_dir/host/bin/sed' "$bundle"
grep -Fq 'make tools/meson/clean' "$bundle"
grep -Fq 'make tools/meson/compile -j1 V=s' "$bundle"
grep -Fq "printf 'CONFIG_TARGET_MULTI_PROFILE=y" "$compose"
grep -Fq "printf 'CONFIG_TARGET_DEVICE_%s_%s_DEVICE_%s=y" "$compose"
! grep -Fq "printf 'CONFIG_TARGET_%s_%s_DEVICE_%s=y" "$compose"
grep -Fq '[[ "$platform" == qcom && "$subtarget" == ipq60xx && "$feature_set" != core ]]' "$compose"
grep -Fq '# CONFIG_KERNEL_CC_OPTIMIZE_FOR_PERFORMANCE is not set' "$compose"
grep -Fq 'CONFIG_KERNEL_CC_OPTIMIZE_FOR_SIZE=y' "$compose"
grep -Fq 'ln -s /usr/bin/openssl staging_dir/host/bin/openssl' "$bundle"
grep -Fq '041-mt-wifi-ap-only-sae-guards.patch' "$compose"
grep -Fq 'group: okwrt-${{ inputs.platform }}-${{ inputs.edition }}-${{ inputs.scope }}-${{ github.ref }}' "$shard_workflow"
[[ "$(grep -Fc '+#include "rt_config.h"' "$mtk_ap_patch")" -eq 4 ]]
grep -Fq -- $'-\t\tnetif_rx_ni(pOSPkt);' "$mtk_ap_patch"
grep -Fq -- $'+\t\tnetif_rx(pOSPkt);' "$mtk_ap_patch"
grep -Fq -- '-#include "eeprom/mt7986_e2p_ePAeLNA.h"' "$mtk_ap_patch"
grep -Fq 'generic mt7986_e2p.h' "$mtk_ap_patch"
grep -Fq -- '--- a/mt_wifi/chips/mt7986_dbg.c' "$mtk_ap_patch"
grep -Fq '+#ifdef CONFIG_WLAN_SERVICE' "$mtk_ap_patch"
grep -Fq '+#endif /* CONFIG_WLAN_SERVICE */' "$mtk_ap_patch"
grep -Fzq -- $'+#ifdef CONFIG_WLAN_SERVICE\n-\tdbg_ops->ctrl_manual_hetb_tx = chip_ctrl_manual_hetb_tx;\n-\tdbg_ops->ctrl_manual_hetb_rx = chip_ctrl_manual_hetb_rx;\n-\tdbg_ops->chip_ctrl_spe = chip_ctrl_asic_spe;\n+        dbg_ops->ctrl_manual_hetb_tx = chip_ctrl_manual_hetb_tx;\n+        dbg_ops->ctrl_manual_hetb_rx = chip_ctrl_manual_hetb_rx;\n+        dbg_ops->chip_ctrl_spe = chip_ctrl_asic_spe;\n+#endif /* CONFIG_WLAN_SERVICE */' "$mtk_ap_patch"
grep -Fq -- '--- a/mt_wifi/mcu/mt_cmd.c' "$mtk_ap_patch"
grep -Fq -- $'-\t\tfor (ant_seq = 0 ; ant_seq < GET_MAX_PATH(chip_cap, SwChCfg.BandIdx, 1) ; ant_seq++)' "$mtk_ap_patch"
grep -Fq -- $'+\t\tfor (ant_seq = 0; ant_seq < chip_cap->mcs_nss.max_path[SwChCfg.BandIdx][MAX_PATH_RX]; ant_seq++)' "$mtk_ap_patch"
grep -Fq -- '--- a/mt_wifi/ate/ate_agent.c' "$mtk_ap_patch"
[[ "$(grep -Fc $'+\t\t\tMTWF_DBG(ad, DBG_CAT_TEST, DBG_SUBCAT_ALL, DBG_LVL_ERROR' "$mtk_ap_patch")" -eq 1 ]]
grep -Fq -- $'+\t\tMTWF_DBG(ad, DBG_CAT_TEST, DBG_SUBCAT_ALL, DBG_LVL_ERROR, "Invalid string\\n");' "$mtk_ap_patch"
grep -Fq -- $'+\t\t\t\t\tRet = chip_dbg->check_txv(pAd->hdev_ctrl, "NSTS", 0, control_band_idx);' "$mtk_ap_patch"
! grep -Fq -- $'+\t\t\t\t\tRet = chip_dbg->check_txv(pAd->hdev_ctrl, "NSTS", 0);' "$mtk_ap_patch"
grep -Fq -- '--- a/mt_wifi/ate/testmode_ioctl.c' "$mtk_ap_patch"
grep -Fq -- $'+\t\tif (ATEOp->StartContinousTx && Band_idx < TESTMODE_BAND_NUM) {' "$mtk_ap_patch"
grep -Fq -- $'+\tif (band_idx >= TESTMODE_BAND_NUM) {' "$mtk_ap_patch"
grep -Fq -- $'+\t\tMTWF_DBG(ad, DBG_CAT_TEST, DBG_SUBCAT_ALL, DBG_LVL_ERROR,' "$mtk_ap_patch"
[[ "$(grep -Fc $'+\t\tRet = NDIS_STATUS_INVALID_DATA;' "$mtk_ap_patch")" -eq 3 ]]
grep -Fq -- $'+\t\t\t\tRet = NDIS_STATUS_INVALID_DATA;' "$mtk_ap_patch"
! grep -Eq '^\+.*(TEST_DBDC_BAND_NUM|SERV_LOG|SERV_STATUS_AGENT_INVALID_)' "$mtk_ap_patch"
grep -Fq -- '--- a/mt_wifi/ate/mt_mac/mt_testmode.c' "$mtk_ap_patch"
grep -Fq '+#ifndef CONFIG_WLAN_SERVICE' "$mtk_ap_patch"
grep -Fq $'+\tPREK_GROUP_CLEAN = 0,' "$mtk_ap_patch"
grep -Fq $'+\tPREK_DPD_6G_PROC = 4,' "$mtk_ap_patch"
grep -Fq $'+\t     ant_loop < cap->mcs_nss.max_path[control_band_idx][MAX_PATH_TX];' "$mtk_ap_patch"
grep -Fq $'+\t     ant_loop < cap->mcs_nss.max_path[control_band_idx][MAX_PATH_RX];' "$mtk_ap_patch"
grep -Fq $'+\tmax_path_num = cap->mcs_nss.max_path[control_band_idx][MAX_PATH_RX];' "$mtk_ap_patch"
[[ "$(grep -Fc $'+\tUINT32 band0_tx_path_backup, band0_rx_path_backup;' "$mtk_ap_patch")" -eq 4 ]]
! grep -Eq '^\+.*(GET_MAX_PATH|u_int32)' "$mtk_ap_patch"
grep -Fq -- '--- a/mt_wifi/embedded/common/rrm.c' "$mtk_ap_patch"
grep -Fq -- '+#ifdef OFFCHANNEL_SCAN_FEATURE' "$mtk_ap_patch"
grep -Fq -- '+#endif /* OFFCHANNEL_SCAN_FEATURE */' "$mtk_ap_patch"
grep -Fq -- $'+\t\t\tpBcnReqData->Incap = 1;' "$mtk_ap_patch"
grep -Fq -- $'+\t\t\tRRM_EnqueuePeerBeaconRep(pAd, pBcnReqData,' "$mtk_ap_patch"
grep -Fq -- $'+\t\t}' "$mtk_ap_patch"
! grep -Fq -- '+#ifdef CONFIG_STA_SUPPORT' "$mtk_ap_patch"
grep -Fq '#if defined(DOT11_SAE_SUPPORT) || defined(SUPP_SAE_SUPPORT)' "$mtk_ap_patch"
[[ "$(grep -Fc '+#if defined(DOT11_SAE_SUPPORT) || defined(SUPP_SAE_SUPPORT)' "$mtk_ap_patch")" -eq 2 ]]
grep -Fq 'struct _RTMP_ADAPTER *pAd = (struct _RTMP_ADAPTER *)wdev->sys_handle;' "$mtk_ap_patch"
grep -Fq '+#endif /* DOT11_SAE_SUPPORT */' "$mtk_ap_patch"
grep -Fq '+#ifdef DOT11R_FT_SUPPORT' "$mtk_ap_patch"
# Move only the FT-specific brace behind its guard; keep the WPA2 block closed.
grep -Fzq -- $'+#ifdef DOT11R_FT_SUPPORT\n \t\t\t\t}\n-\t\t\t}\n+#endif\n+\t\t\t}' "$mtk_ap_patch"
grep -Fq "s/+python3-pkg-resources[[:space:]]*//" "$install_packages"
grep -Fq "s/+python3-email[[:space:]]*//" "$install_packages"
grep -Fxq 'CONFIG_PACKAGE_luci-app-daed=y' "$standard_config"
grep -Fxq 'CONFIG_PACKAGE_daed=y' "$standard_config"
grep -Fxq 'CONFIG_KERNEL_DEBUG_INFO_BTF=y' "$standard_config"
grep -Fxq '# CONFIG_KERNEL_DEBUG_INFO_REDUCED is not set' "$standard_config"
grep -Fxq 'CONFIG_KERNEL_BPF_EVENTS=y' "$standard_config"
grep -Fq 'Required Standard package is missing from $variant: $package' "$bundle"
grep -Fq 'luci-app-daed daed daed-geoip daed-geosite' "$bundle"
grep -Fq -- '-size +1M' "$bundle"
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
grep -Fxq 'CONFIG_MTK_MGMT_TXPWR_CTRL=y' "$mtk_config"
grep -Fxq 'CONFIG_MTK_DOT11K_RRM_SUPPORT=y' "$mtk_config"
grep -Fxq 'CONFIG_MTK_APCLI_SUPPORT=y' "$mtk_config"
grep -Fxq '# CONFIG_MTK_WPA3_SUPPORT is not set' "$mtk_config"
grep -Fxq '# CONFIG_MTK_PRE_CAL_TRX_SET1_SUPPORT is not set' "$mtk_config"
grep -Fxq '# CONFIG_MTK_RLM_CAL_CACHE_SUPPORT is not set' "$mtk_config"
grep -Fxq '# CONFIG_MTK_PRE_CAL_TRX_SET2_SUPPORT is not set' "$mtk_config"
! grep -Fq 'CONFIG_MTK_WIFI_MODE_BOTH=' "$mtk_config"
! grep -Fq 'CONFIG_MTK_MT_STA_SUPPORT=' "$mtk_config"
! grep -Fxq 'CONFIG_MTK_WPA3_SUPPORT=y' "$mtk_config"
grep -Fxq 'CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_generic-qmi-wwan=y' "$standard_usb_config"
grep -Fxq '# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_vendor-qmi-wwan is not set' "$standard_usb_config"
grep -Fxq '# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_nss-qmi-wwan is not set' "$standard_usb_config"
grep -Fxq 'CONFIG_PACKAGE_kmod-ipt-nat=y' "$mtk_config"
grep -Fxq 'CONFIG_PACKAGE_kmod-warp=y' "$mtk_config"
grep -Fxq 'CONFIG_MTK_WLAN_HOOK=y' "$mtk_config"
grep -Fxq 'CONFIG_MTK_FAST_NAT_SUPPORT=y' "$mtk_config"
grep -Fxq 'CONFIG_MTK_WHNAT_SUPPORT=y' "$mtk_config"
grep -Fxq 'CONFIG_MTK_WARP_V2=y' "$mtk_config"

world_line="$(grep -nF 'if ! make -j"$(nproc)"; then' "$bundle" | cut -d: -f1)"
daed_line="$(grep -nF 'make package/feeds/packages/daed/compile -j1 V=s' "$bundle" | cut -d: -f1)"
((daed_line > world_line)) || {
  echo 'daed retry must run after the first world build' >&2
  exit 1
}

echo 'Build bundle regression checks passed.'
