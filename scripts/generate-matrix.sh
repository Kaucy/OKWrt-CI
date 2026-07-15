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
  local platform="$1" target="$2" subtarget="$3" edition="$4" channel="$5" soc="$6" device="$7"
  [[ "$channel_filter" == all || "$channel_filter" == "$channel" ]] || return 0
  [[ "$platform_filter" == all || "$platform_filter" == "$platform" ]] || return 0
  [[ "$edition_filter" == all || "$edition_filter" == "$edition" ]] || return 0
  local group_soc=all
  [[ "$platform:$edition" == mtk:pro ]] && group_soc="$soc"
  local key="$platform|$target|$subtarget|$edition|$channel|$group_soc"
  groups["$key"]+=" $device"
}

if [[ "$scope" == smoke ]]; then
  declare -A selected_rows=() selected_ranks=()
  while IFS=$'\t' read -r platform target subtarget device _name soc edition channel max_feature; do
    [[ "$platform" == platform ]] && continue
    [[ "$channel_filter" == all || "$channel_filter" == "$channel" ]] || continue
    [[ "$platform_filter" == all || "$platform_filter" == "$platform" ]] || continue
    [[ "$edition_filter" == all || "$edition_filter" == "$edition" ]] || continue
    key="$platform|$edition|$channel"
    rank="${feature_ranks[$max_feature]}"
    if [[ -z "${selected_rows[$key]:-}" || "$rank" -gt "${selected_ranks[$key]}" ]]; then
      selected_rows[$key]="$platform|$target|$subtarget|$edition|$channel|$soc|$device"
      selected_ranks[$key]="$rank"
    fi
  done < "$catalog"
  while IFS= read -r key; do
    IFS='|' read -r platform target subtarget edition channel soc device <<< "${selected_rows[$key]}"
    add_group_device "$platform" "$target" "$subtarget" "$edition" "$channel" "$soc" "$device"
  done < <(printf '%s\n' "${!selected_rows[@]}" | sort)
else
  while IFS=$'\t' read -r platform target subtarget device _name soc edition channel max_feature; do
    [[ "$platform" == platform ]] && continue
    case "$platform:$target:$subtarget" in
      qcom:qualcommax:ipq50xx|qcom:qualcommax:ipq60xx|qcom:qualcommax:ipq807x|qcom:qualcommbe:ipq95xx|mtk:mediatek:filogic) ;;
      *)
        echo "unsupported device scope in catalog: $platform/$target/$subtarget ($device)" >&2
        exit 1
        ;;
    esac
    add_group_device "$platform" "$target" "$subtarget" "$edition" "$channel" "$soc" "$device"
  done < "$catalog"
fi

while IFS= read -r key; do
  IFS='|' read -r platform target subtarget edition channel soc <<< "$key"
  read -r -a devices <<< "${groups[$key]}"
  for ((offset=0, chunk=1; offset<${#devices[@]}; offset+=chunk_size, chunk++)); do
    selected=("${devices[@]:offset:chunk_size}")
    device_list="${selected[*]}"
    items="$(jq -c \
      --arg platform "$platform" --arg target "$target" --arg subtarget "$subtarget" \
      --arg edition "$edition" --arg channel "$channel" \
      --arg soc "$soc" --arg devices "$device_list" --argjson chunk "$chunk" --argjson device_count "${#selected[@]}" \
      '. + [{platform:$platform,target:$target,subtarget:$subtarget,edition:$edition,channel:$channel,soc:$soc,devices:$devices,chunk:$chunk,device_count:$device_count}]' \
      <<< "$items")"
  done
done < <(printf '%s\n' "${!groups[@]}" | sort)

jq -c '{include:.}' <<< "$items"
