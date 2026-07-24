#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

variant="$fixture/input/bundle/mediatek-filogic-open-edge-standard-part1"
mkdir -p "$variant"
cat > "$variant/build-metadata.txt" <<'EOF'
channel=edge
feature_set=standard
subtarget=filogic
kernel_profile=kernel-default
EOF

ipq60_variant="$fixture/input/bundle/qualcommax-ipq60xx-pro-edge-standard-kernel-6m-part1"
mkdir -p "$ipq60_variant"
cat > "$ipq60_variant/build-metadata.txt" <<'EOF'
channel=edge
feature_set=standard
subtarget=ipq60xx
kernel_profile=kernel-6m
EOF
truncate -s 2M "$ipq60_variant/immortalwrt-jdcloud_re-cs-02-squashfs-sysupgrade.bin"

ipq60_large_variant="$fixture/input/bundle/qualcommax-ipq60xx-pro-edge-standard-kernel-large-part1"
mkdir -p "$ipq60_large_variant"
cat > "$ipq60_large_variant/build-metadata.txt" <<'EOF'
channel=edge
feature_set=standard
subtarget=ipq60xx
kernel_profile=kernel-large
EOF
truncate -s 2M "$ipq60_large_variant/immortalwrt-linksys_mr7500-squashfs-sysupgrade.bin"

truncate -s 2M "$variant/immortalwrt-device-squashfs-sysupgrade.bin"
truncate -s 2M "$variant/immortalwrt-device-ubootmod-squashfs-sysupgrade.itb"
truncate -s 2M "$variant/immortalwrt-device-squashfs-factory.ubi"
printf placeholder > "$variant/immortalwrt-device-squashfs-factory.bin"
printf auxiliary > "$variant/immortalwrt-device-kernel.bin"
printf auxiliary > "$variant/immortalwrt-device-initramfs.itb"
printf diagnostic > "$variant/config.txt"
printf diagnostic > "$variant/profiles.json"
printf diagnostic > "$variant/build-failure.log"

for artifact in "$variant" "$ipq60_variant" "$ipq60_large_variant"; do
  (cd "$artifact" && sha256sum -- * > SHA256SUMS)
done

"$repo/scripts/prepare-release-assets.sh" "$fixture/input" "$fixture/output"

test -f "$fixture/output/edge/filogic/standard--immortalwrt-device-squashfs-sysupgrade.bin"
test -f "$fixture/output/edge/filogic/standard--immortalwrt-device-ubootmod-squashfs-sysupgrade.itb"
test -f "$fixture/output/edge/filogic/standard--immortalwrt-device-squashfs-factory.ubi"
test ! -e "$fixture/output/edge/filogic/standard--immortalwrt-device-squashfs-factory.bin"
test -f "$fixture/output/edge/filogic/SHA256SUMS-standard.txt"
test -f "$fixture/output/edge/ipq60xx/standard--kernel-6m--immortalwrt-jdcloud_re-cs-02-squashfs-sysupgrade.bin"
test -f "$fixture/output/edge/ipq60xx/standard--kernel-large--immortalwrt-linksys_mr7500-squashfs-sysupgrade.bin"
test -f "$fixture/output/edge/ipq60xx/SHA256SUMS-standard.txt"
test "$(find "$fixture/output" -type f | wc -l)" -eq 7
! find "$fixture/output" -type f \( -name '*kernel*' -o -name '*initramfs*' -o -name '*config*' -o -name '*profiles*' \) | grep -q .
(cd "$fixture/output/edge/filogic" && sha256sum -c SHA256SUMS-standard.txt)
(cd "$fixture/output/edge/ipq60xx" && sha256sum -c SHA256SUMS-standard.txt)

printf tampered >> "$variant/immortalwrt-device-squashfs-sysupgrade.bin"
if "$repo/scripts/prepare-release-assets.sh" "$fixture/input" "$fixture/tampered-output"; then
  echo 'Tampered artifact unexpectedly passed checksum validation.' >&2
  exit 1
fi
