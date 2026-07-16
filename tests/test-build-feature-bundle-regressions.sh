#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
bundle="$root/scripts/build-feature-bundle.sh"
mtk_config="$root/config/edition/mtk-pro.config"

grep -Fq 'ln -s /usr/bin/sed staging_dir/host/bin/sed' "$bundle"
grep -Fq 'rm -f "$out/sha256sums" "$out/SHA256SUMS"' "$bundle"
grep -Fxq 'CONFIG_PACKAGE_kmod-ipt-nat=y' "$mtk_config"

echo 'Build bundle regression checks passed.'
