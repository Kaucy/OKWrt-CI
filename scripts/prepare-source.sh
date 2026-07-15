#!/usr/bin/env bash
set -euo pipefail

topdir="${1:?OpenWrt source directory is required}"
platform="${2:?platform is required}"
edition="${3:?edition is required}"
channel="${4:?channel is required}"

# 标准 ImmortalWrt 暂无京东云 RE-CS-02 profile。Open 产品线仍以
# ImmortalWrt 为源码上游，但从自己的 LibWrt Fork 同步可审计的设备支持层；
# DTS 会移除 NSS 专用 include，继续使用标准 ESS/EDMA 与 ath11k。
if [[ "$platform:$edition" != qcom:open ]]; then
  exit 0
fi

branch=25.12-nss
[[ "$channel" == edge ]] && branch=main-nss

support="$(mktemp -d)"
trap 'rm -rf "$support"' EXIT

git clone --depth=1 --filter=blob:none --sparse --single-branch \
  --branch "$branch" https://github.com/Kaucy/LibWrt.git "$support"
git -C "$support" sparse-checkout set \
  target/linux/qualcommax/image \
  target/linux/qualcommax/ipq60xx/base-files \
  target/linux/qualcommax/files/arch/arm64/boot/dts/qcom \
  package/firmware/ipq-wifi

cp "$support/target/linux/qualcommax/image/ipq60xx.mk" \
  "$topdir/target/linux/qualcommax/image/ipq60xx.mk"
cp -a "$support/target/linux/qualcommax/ipq60xx/base-files/." \
  "$topdir/target/linux/qualcommax/ipq60xx/base-files/"
cp "$support/package/firmware/ipq-wifi/Makefile" \
  "$topdir/package/firmware/ipq-wifi/Makefile"

dts_dir="$topdir/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"
cp "$support/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6010-re-cs.dtsi" "$dts_dir/"
cp "$support/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6010-re-cs-02.dts" "$dts_dir/"

sed -i '/#include "ipq6018-nss.dtsi"/d' "$dts_dir/ipq6010-re-cs.dtsi"
sed -i '/#include "ipq6018.dtsi"/a #include "ipq6018-cp-cpu.dtsi"' \
  "$dts_dir/ipq6010-re-cs.dtsi"

grep -q 'TARGET_DEVICES += jdcloud_re-cs-02' \
  "$topdir/target/linux/qualcommax/image/ipq60xx.mk"
grep -q 'ipq6018-cp-cpu.dtsi' "$dts_dir/ipq6010-re-cs.dtsi"
! grep -q 'ipq6018-nss.dtsi' "$dts_dir/ipq6010-re-cs.dtsi"
