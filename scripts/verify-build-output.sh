#!/usr/bin/env bash
set -euo pipefail

output="${1:?build output directory is required}"
shift
(($#)) || { echo 'At least one device profile is required.' >&2; exit 1; }

[[ -d "$output" ]] || {
  echo "Build output directory does not exist: $output" >&2
  exit 1
}

is_flashable_name() {
  case "$1" in
    *-sysupgrade.bin|*-factory.bin|*-sysupgrade.itb|*-factory.itb|\
    *-sysupgrade.ubi|*-factory.ubi|*-combined*.img.gz) return 0 ;;
    *) return 1 ;;
  esac
}

shopt -s nullglob
profile_files=("$output"/*profiles.json)
shopt -u nullglob
((${#profile_files[@]} == 1)) || {
  echo "Expected exactly one profiles.json in $output; found ${#profile_files[@]}." >&2
  exit 1
}
profiles="${profile_files[0]}"

for device in "$@"; do
  mapfile -t images < <(
    jq -er --arg device "$device" \
      '.profiles[$device].images[]?.name | select(type == "string")' \
      "$profiles"
  )
  ((${#images[@]})) || {
    echo "Device is missing from profiles.json or has no images: $device" >&2
    exit 1
  }

  flashable=false
  for image in "${images[@]}"; do
    is_flashable_name "$image" || continue
    firmware="$output/$image"
    if [[ -f "$firmware" ]] && (( $(stat -c '%s' "$firmware") > 1048576 )); then
      flashable=true
      break
    fi
  done
  $flashable || {
    echo "No flashable firmware larger than 1 MiB was produced for device: $device" >&2
    exit 1
  }
done
