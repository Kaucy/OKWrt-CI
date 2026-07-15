#!/usr/bin/env bash
set -euo pipefail

topdir="${1:?OpenWrt source directory is required}"
feature_set="${2:?feature set is required}"
pkgdir="$topdir/package/okwrt"
mkdir -p "$pkgdir"

replace_package() {
  local name="$1" repo="$2" branch="$3"
  rm -rf "$pkgdir/$name"
  git clone --depth=1 --single-branch --branch "$branch" "$repo" "$pkgdir/$name"
}

# OK-Wrt 始终使用 Argon。固定 25.12 分支，避免主题主分支接口漂移。
replace_package argon https://github.com/sbwml/luci-theme-argon.git openwrt-25.12

case "$feature_set" in
  core)
    ;;
  standard|standard-usb|ultra)
    replace_package netspeedtest https://github.com/Kaucy/netspeedtest.git main

    # OpenClash 仓库很大，只取 LuCI 包目录。
    tmp="$pkgdir/.openclash"
    rm -rf "$tmp" "$pkgdir/luci-app-openclash"
    git clone --depth=1 --filter=blob:none --sparse --branch dev \
      https://github.com/vernesong/OpenClash.git "$tmp"
    git -C "$tmp" sparse-checkout set luci-app-openclash
    mv "$tmp/luci-app-openclash" "$pkgdir/luci-app-openclash"
    rm -rf "$tmp"
    ;;
  *)
    echo "Unknown feature set: $feature_set" >&2
    exit 1
    ;;
esac

if [[ "$feature_set" == standard-usb || "$feature_set" == ultra ]]; then
  replace_package diskman https://github.com/sbwml/luci-app-diskman.git main
  replace_package qmodem https://github.com/FUjr/QModem.git main
fi

if [[ "$feature_set" == ultra ]]; then
  replace_package dockerman https://github.com/sbwml/luci-app-dockerman.git openwrt-25.12
fi
