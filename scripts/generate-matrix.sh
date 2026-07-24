#!/usr/bin/env bash
set -euo pipefail

scope="${1:-all}"
channel_filter="${2:-all}"
platform_filter="${3:-all}"
edition_filter="${4:-all}"
catalog="${GITHUB_WORKSPACE:-$(pwd)}/config/devices.tsv"
chunk_size="${DEVICE_CHUNK_SIZE:-25}"
items='[]'

declare -A groups=()
declare -A feature_ranks=([core]=0 [standard]=1 [standard-usb]=2 [ultra]=3)

add_group_device() {
  local platform="$1" target="$2" subtarget="$3" edition="$4" channel="$5" soc="$6" kernel_profile="$7" device="$8"
  case "$platform:$subtarget:$kernel_profile" in
    qcom:ipq60xx:kernel-6m|qcom:ipq60xx:kernel-large|*:kernel-default) ;;
    *) echo "invalid kernel profile in catalog for $platform/$subtarget/$device: $kernel_profile" >&2; exit 1 ;;
  esac
  [[ "$channel_filter" == all || "$channel_filter" == "$channel" ]] || return 0
  [[ "$platform_filter" == all || "$platform_filter" == "$platform" ]] || return 0
  [[ "$edition_filter" == all || "$edition_filter" == "$edition" ]] || return 0
  local group_soc=all
  [[ "$platform:$edition" == mtk:pro ]] && group_soc="$soc"
  local key="$platform|$target|$subtarget|$edition|$channel|$group_soc|$kernel_profile"
  groups["$key"]+=" $device"
}

if [[ "$scope" == smoke ]]; then
  declare -A selected_rows=() selected_ranks=()
  while IFS=$'\t' read -r platform target subtarget device _name soc edition channel max_feature kernel_profile; do
    [[ "$platform" == platform ]] && continue
    [[ "$channel_filter" == all || "$channel_filter" == "$channel" ]] || continue
    [[ "$platform_filter" == all || "$platform_filter" == "$platform" ]] || continue
    [[ "$edition_filter" == all || "$edition_filter" == "$edition" ]] || continue
    smoke_profile=kernel-default
    [[ "$platform:$subtarget" == qcom:ipq60xx ]] && smoke_profile="$kernel_profile"
    smoke_soc=all
    [[ "$platform:$edition" == mtk:pro ]] && smoke_soc="$soc"
    # Smoke must cover every target family, not merely one kernel-default
    # Qualcomm device per channel.  Without target/subtarget in this key,
    # IPQ50xx, IPQ807x and IPQ95xx collapse into the same bucket and a green
    # smoke run can leave two complete Qualcomm families entirely untested.
    key="$platform|$target|$subtarget|$edition|$channel|$smoke_profile|$smoke_soc"
    rank="${feature_ranks[$max_feature]}"
    if [[ -z "${selected_rows[$key]:-}" || "$rank" -gt "${selected_ranks[$key]}" ]]; then
      selected_rows[$key]="$platform|$target|$subtarget|$edition|$channel|$soc|$kernel_profile|$device"
      selected_ranks[$key]="$rank"
    fi
  done < "$catalog"
  while IFS= read -r key; do
    IFS='|' read -r platform target subtarget edition channel soc kernel_profile device <<< "${selected_rows[$key]}"
    add_group_device "$platform" "$target" "$subtarget" "$edition" "$channel" "$soc" "$kernel_profile" "$device"
  done < <(printf '%s\n' "${!selected_rows[@]}" | sort)
else
  while IFS=$'\t' read -r platform target subtarget device _name soc edition channel max_feature kernel_profile; do
    [[ "$platform" == platform ]] && continue
    case "$platform:$target:$subtarget" in
      qcom:qualcommax:ipq50xx|qcom:qualcommax:ipq60xx|qcom:qualcommax:ipq807x|qcom:qualcommbe:ipq95xx|mtk:mediatek:filogic) ;;
      *)
        echo "unsupported device scope in catalog: $platform/$target/$subtarget ($device)" >&2
        exit 1
        ;;
    esac
    add_group_device "$platform" "$target" "$subtarget" "$edition" "$channel" "$soc" "$kernel_profile" "$device"
  done < "$catalog"
fi

while IFS= read -r key; do
  IFS='|' read -r platform target subtarget edition channel soc kernel_profile <<< "$key"
  read -r -a devices <<< "${groups[$key]}"
  for ((offset=0, chunk=1; offset<${#devices[@]}; offset+=chunk_size, chunk++)); do
    selected=("${devices[@]:offset:chunk_size}")
    device_list="${selected[*]}"
    items="$(jq -c \
      --arg platform "$platform" --arg target "$target" --arg subtarget "$subtarget" \
      --arg edition "$edition" --arg channel "$channel" \
      --arg soc "$soc" --arg kernel_profile "$kernel_profile" --arg devices "$device_list" \
      --argjson chunk "$chunk" --argjson device_count "${#selected[@]}" \
      '. + [{platform:$platform,target:$target,subtarget:$subtarget,edition:$edition,channel:$channel,soc:$soc,kernel_profile:$kernel_profile,devices:$devices,chunk:$chunk,device_count:$device_count}]' \
      <<< "$items")"
  done
done < <(printf '%s\n' "${!groups[@]}" | sort)

jq -c '{include:.}' <<< "$items"
