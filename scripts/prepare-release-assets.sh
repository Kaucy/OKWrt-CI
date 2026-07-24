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
  checksum_file="$variant_dir/SHA256SUMS"
  [[ -f "$checksum_file" ]] || {
    echo "Artifact checksum list is missing: $checksum_file" >&2
    exit 1
  }
  (
    cd "$variant_dir"
    sha256sum -c SHA256SUMS
  )

  channel="$(metadata_value "$metadata" channel)"
  feature="$(metadata_value "$metadata" feature_set)"
  family="$(metadata_value "$metadata" subtarget)"
  kernel_profile="$(metadata_value "$metadata" kernel_profile)"

  case "$channel" in lts|edge) ;; *) echo "Invalid channel in $metadata: $channel" >&2; exit 1 ;; esac
  case "$feature" in core|standard|standard-usb|ultra) ;; *) echo "Invalid feature set in $metadata: $feature" >&2; exit 1 ;; esac
  case "$family" in ipq50xx|ipq60xx|ipq807x|ipq95xx|filogic) ;;
    *) echo "Invalid device family in $metadata: $family" >&2; exit 1 ;;
  esac
  if [[ "$family" == ipq60xx ]]; then
    case "$kernel_profile" in kernel-6m|kernel-large) ;;
      *) echo "Invalid kernel profile in $metadata: $kernel_profile" >&2; exit 1 ;;
    esac
    kernel_prefix="$kernel_profile--"
  else
    [[ "$kernel_profile" == kernel-default ]] || {
      echo "Invalid kernel profile in $metadata: $kernel_profile" >&2
      exit 1
    }
    kernel_prefix=""
  fi

  # GitHub Release assets are flat.  Keep each device family in a separate
  # stable Release, then use the feature prefix to sort assets inside it.
  destination="$output/$channel/$family"
  mkdir -p "$destination"
  firmware_found=false
  while IFS= read -r -d '' firmware; do
    base="$(basename "$firmware")"
    is_firmware "$base" || continue
    firmware_found=true
    published="$destination/$feature--$kernel_prefix$base"
    [[ ! -e "$published" ]] || {
      echo "Duplicate Release asset: $published" >&2
      exit 1
    }
    cp -p "$firmware" "$published"
  done < <(find "$variant_dir" -maxdepth 1 -type f -print0)
  $firmware_found || {
    echo "Artifact contains metadata but no publishable firmware: $variant_dir" >&2
    exit 1
  }
done < <(find "$input" -type f -name build-metadata.txt -print0)

while IFS= read -r -d '' family_dir; do
  for feature in core standard standard-usb ultra; do
    files=("$family_dir/$feature--"*)
    [[ -e "${files[0]}" ]] || continue
    (
      cd "$family_dir"
      names=()
      for file in "${files[@]}"; do names+=("$(basename "$file")"); done
      sha256sum -- "${names[@]}" > "SHA256SUMS-$feature.txt"
    )
  done
done < <(find "$output" -mindepth 2 -maxdepth 2 -type d -print0)
