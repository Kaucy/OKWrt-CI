#!/usr/bin/env bash
set -euo pipefail

scope="${1:-all}"
channel_filter="${2:-all}"
catalog="${GITHUB_WORKSPACE:-$(pwd)}/config/devices.tsv"
chunk_size="${DEVICE_CHUNK_SIZE:-25}"
items='[]'

declare -A groups=()
declare -A ranks=([core]=0 [standard]=1 [standard-usb]=2 [ultra]=3)
features=(core standard standard-usb ultra)

add_group_device() {
  local platform="$1" target="$2" subtarget="$3" edition="$4" channel="$5" feature="$6" soc="$7" device="$8"
  [[ "$channel_filter" == all || "$channel_filter" == "$channel" ]] || return 0
  local group_soc=all
  [[ "$platform:$edition" == mtk:pro ]] && group_soc="$soc"
  local key="$platform|$target|$subtarget|$edition|$channel|$feature|$group_soc"
  groups["$key"]+=" $device"
}

if [[ "$scope" == smoke ]]; then
  add_group_device qcom qualcommax ipq60xx open edge core ipq6010 jdcloud_re-cs-02
  add_group_device mtk mediatek filogic open lts core mt7981 cudy_tr3000-v1
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
    for feature in "${features[@]}"; do
      (( ranks[$feature] <= ranks[$max_feature] )) || continue
      add_group_device "$platform" "$target" "$subtarget" "$edition" "$channel" "$feature" "$soc" "$device"
    done
  done < "$catalog"
fi

while IFS= read -r key; do
  IFS='|' read -r platform target subtarget edition channel feature soc <<< "$key"
  read -r -a devices <<< "${groups[$key]}"
  for ((offset=0, chunk=1; offset<${#devices[@]}; offset+=chunk_size, chunk++)); do
    selected=("${devices[@]:offset:chunk_size}")
    device_list="${selected[*]}"
    items="$(jq -c \
      --arg platform "$platform" --arg target "$target" --arg subtarget "$subtarget" \
      --arg edition "$edition" --arg channel "$channel" --arg feature "$feature" \
      --arg soc "$soc" --arg devices "$device_list" --argjson chunk "$chunk" --argjson device_count "${#selected[@]}" \
      '. + [{platform:$platform,target:$target,subtarget:$subtarget,edition:$edition,channel:$channel,feature:$feature,soc:$soc,devices:$devices,chunk:$chunk,device_count:$device_count}]' \
      <<< "$items")"
  done
done < <(printf '%s\n' "${!groups[@]}" | sort)

jq -c '{include:.}' <<< "$items"
