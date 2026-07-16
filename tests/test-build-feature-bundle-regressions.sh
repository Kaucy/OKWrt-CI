#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
bundle="$root/scripts/build-feature-bundle.sh"
compose="$root/scripts/compose-config.sh"
mtk_config="$root/config/edition/mtk-pro.config"

# Keep the smoke checks cheap: these assertions cover the three CI regressions
# before a multi-hour firmware build is started.
grep -Fq 'ln -s /usr/bin/sed staging_dir/host/bin/sed' "$bundle"
grep -Fq 'make tools/meson/clean' "$bundle"
grep -Fq 'make tools/meson/compile -j1 V=s' "$bundle"
grep -Fq "printf 'CONFIG_TARGET_MULTI_PROFILE=y" "$compose"
grep -Fq 'ln -s /usr/bin/openssl staging_dir/host/bin/openssl' "$bundle"
grep -Fq 'make package/feeds/packages/daed/compile -j1 V=s' "$bundle"
grep -Fq 'make package/mtk/drivers/mt_wifi/clean' "$bundle"
grep -Fq 'make package/mtk/drivers/mt_wifi/compile -j1 V=s' "$bundle"
grep -Fq 'rm -f "$out/sha256sums" "$out/SHA256SUMS"' "$bundle"
grep -Fxq 'CONFIG_PACKAGE_kmod-ipt-nat=y' "$mtk_config"

world_line="$(grep -nF 'if ! make -j"$(nproc)"; then' "$bundle" | cut -d: -f1)"
daed_line="$(grep -nF 'make package/feeds/packages/daed/compile -j1 V=s' "$bundle" | cut -d: -f1)"
((daed_line > world_line)) || {
  echo 'daed retry must run after the first world build' >&2
  exit 1
}

echo 'Build bundle regression checks passed.'
