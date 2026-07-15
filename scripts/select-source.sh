#!/usr/bin/env bash
set -euo pipefail

platform="$1"
edition="$2"
channel="$3"

case "$platform:$edition" in
  qcom:open)
    repo="https://github.com/Kaucy/immortalwrt.git"
    upstream="https://github.com/immortalwrt/immortalwrt.git"
    [[ "$channel" == lts ]] && branch="openwrt-25.12" || branch="master"
    ;;
  qcom:pro)
    repo="https://github.com/Kaucy/LibWrt.git"
    upstream="https://github.com/LiBwrt/openwrt-6.x.git"
    [[ "$channel" == lts ]] && branch="25.12-nss" || branch="main-nss"
    ;;
  mtk:open)
    repo="https://github.com/Kaucy/immortalwrt.git"
    upstream="https://github.com/immortalwrt/immortalwrt.git"
    [[ "$channel" == lts ]] && branch="openwrt-25.12" || branch="master"
    ;;
  mtk:pro)
    repo="https://github.com/Kaucy/immortalwrt-mt798x-rebase.git"
    upstream="https://github.com/chasey-dev/immortalwrt-mt798x-rebase.git"
    branch="25.12"
    ;;
  *)
    echo "Unsupported source tuple: $platform/$edition/$channel" >&2
    exit 1
    ;;
esac

cat <<EOF
repo=$repo
upstream=$upstream
branch=$branch
EOF
