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
EOF

printf firmware > "$variant/immortalwrt-device-squashfs-sysupgrade.bin"
printf firmware > "$variant/immortalwrt-device-ubootmod-squashfs-sysupgrade.itb"
printf firmware > "$variant/immortalwrt-device-squashfs-factory.ubi"
printf auxiliary > "$variant/immortalwrt-device-kernel.bin"
printf auxiliary > "$variant/immortalwrt-device-initramfs.itb"
printf diagnostic > "$variant/config.txt"
printf diagnostic > "$variant/profiles.json"
printf diagnostic > "$variant/build-failure.log"

"$repo/scripts/prepare-release-assets.sh" "$fixture/input" "$fixture/output"

test -f "$fixture/output/edge/standard--immortalwrt-device-squashfs-sysupgrade.bin"
test -f "$fixture/output/edge/standard--immortalwrt-device-ubootmod-squashfs-sysupgrade.itb"
test -f "$fixture/output/edge/standard--immortalwrt-device-squashfs-factory.ubi"
test -f "$fixture/output/edge/SHA256SUMS-standard.txt"
test "$(find "$fixture/output" -type f | wc -l)" -eq 4
! find "$fixture/output" -type f \( -name '*kernel*' -o -name '*initramfs*' -o -name '*config*' -o -name '*profiles*' \) | grep -q .
(cd "$fixture/output/edge" && sha256sum -c SHA256SUMS-standard.txt)
