#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

truncate -s 2M "$fixture/device-one-squashfs-sysupgrade.bin"
truncate -s 2M "$fixture/device-two-squashfs-factory.ubi"
printf auxiliary > "$fixture/device-two-kernel.bin"
cat > "$fixture/profiles.json" <<'EOF'
{
  "profiles": {
    "device_one": {
      "images": [{"name": "device-one-squashfs-sysupgrade.bin"}]
    },
    "device_two": {
      "images": [
        {"name": "device-two-kernel.bin"},
        {"name": "device-two-squashfs-factory.ubi"}
      ]
    }
  }
}
EOF

"$root/scripts/verify-build-output.sh" "$fixture" device_one device_two

if "$root/scripts/verify-build-output.sh" "$fixture" device_one missing_device; then
  echo 'A missing device unexpectedly passed output validation.' >&2
  exit 1
fi

truncate -s 1024 "$fixture/device-two-squashfs-factory.ubi"
if "$root/scripts/verify-build-output.sh" "$fixture" device_two; then
  echo 'A sub-1 MiB firmware unexpectedly passed output validation.' >&2
  exit 1
fi

echo 'Per-device firmware validation passed.'
