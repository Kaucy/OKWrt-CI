#!/usr/bin/env bash
set -euo pipefail

scope="${1:-all}"
channel_filter="${2:-all}"
items='[]'

add_item() {
  local platform="$1" edition="$2" channel="$3" feature="$4" device="$5"
  [[ "$channel_filter" == all || "$channel_filter" == "$channel" ]] || return 0
  items="$(jq -c \
    --arg platform "$platform" --arg edition "$edition" \
    --arg channel "$channel" --arg feature "$feature" --arg device "$device" \
    '. + [{platform:$platform,edition:$edition,channel:$channel,feature:$feature,device:$device}]' \
    <<<"$items")"
}

if [[ "$scope" == smoke ]]; then
  add_item qcom pro lts core jdcloud_re-cs-02
  add_item mtk open lts core cudy_tr3000-v1
else
  for edition in open pro; do
    for channel in lts edge; do
      for feature in core standard standard-usb ultra; do
        add_item qcom "$edition" "$channel" "$feature" jdcloud_re-cs-02
      done
      for feature in core standard standard-usb; do
        add_item mtk "$edition" "$channel" "$feature" cudy_tr3000-v1
      done
    done
  done
fi

jq -c '{include:.}' <<<"$items"
