#!/usr/bin/env bash
set -euo pipefail

input="${1:?downloaded artifact directory is required}"
output="${2:?publish directory is required}"

[[ -d "$input" ]] || { echo "Artifact directory does not exist: $input" >&2; exit 1; }
mkdir -p "$output"

metadata_value() {
  local file="$1" key="$2"
  awk -F= -v key="$key" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$file"
}

is_firmware() {
  case "$1" in
    *-sysupgrade.bin|*-factory.bin|*-sysupgrade.itb|*-factory.itb|\
    *-sysupgrade.ubi|*-factory.ubi|*-combined*.img.gz) return 0 ;;
    *) return 1 ;;
  esac
}

while IFS= read -r -d '' metadata; do
  variant_dir="$(dirname "$metadata")"
  channel="$(metadata_value "$metadata" channel)"
  feature="$(metadata_value "$metadata" feature_set)"

  case "$channel" in lts|edge) ;; *) echo "Invalid channel in $metadata: $channel" >&2; exit 1 ;; esac
  case "$feature" in core|standard|standard-usb|ultra) ;; *) echo "Invalid feature set in $metadata: $feature" >&2; exit 1 ;; esac

  destination="$output/$channel"
  mkdir -p "$destination"
  while IFS= read -r -d '' firmware; do
    base="$(basename "$firmware")"
    is_firmware "$base" || continue
    published="$destination/$feature--$base"
    [[ ! -e "$published" ]] || {
      echo "Duplicate Release asset: $published" >&2
      exit 1
    }
    cp -p "$firmware" "$published"
  done < <(find "$variant_dir" -maxdepth 1 -type f -print0)
done < <(find "$input" -type f -name build-metadata.txt -print0)

for channel_dir in "$output"/*; do
  [[ -d "$channel_dir" ]] || continue
  for feature in core standard standard-usb ultra; do
    files=("$channel_dir/$feature--"*)
    [[ -e "${files[0]}" ]] || continue
    (
      cd "$channel_dir"
      names=()
      for file in "${files[@]}"; do names+=("$(basename "$file")"); done
      sha256sum -- "${names[@]}" > "SHA256SUMS-$feature.txt"
    )
  done
done
