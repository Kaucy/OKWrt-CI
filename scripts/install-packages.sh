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

replace_package_tree() {
  local name="$1" repo="$2" branch="$3"
  local destination="$pkgdir/$name"
  rm -rf "$destination"
  git clone --depth=1 --single-branch --branch "$branch" "$repo" "$destination"

  # 这些仓库会覆盖 feeds 中的同名包，移除 feeds 符号链接以避免重复定义。
  while IFS= read -r makefile; do
    package="$(basename "$(dirname "$makefile")")"
    find "$topdir/package/feeds" -mindepth 2 -maxdepth 2 -type l -name "$package" -delete 2>/dev/null || true
  done < <(find "$destination" -mindepth 1 -maxdepth 2 -name Makefile -type f)
}

# OK-Wrt 始终使用 Argon。固定 25.12 分支，避免主题主分支接口漂移。
replace_package argon https://github.com/sbwml/luci-theme-argon.git openwrt-25.12

case "$feature_set" in
  core)
    ;;
  standard|standard-usb|ultra)
    replace_package netspeedtest https://github.com/Kaucy/netspeedtest.git main
    # OpenWrt 25.12 folds these modules into the current Python packages and
    # no longer publishes the two legacy package names. The bundled script
    # does not import either module, so remove only the stale dependencies.
    sed -i \
      -e 's/+python3-pkg-resources[[:space:]]*//' \
      -e 's/+python3-email[[:space:]]*//' \
      "$pkgdir/netspeedtest/luci-app-netspeedtest/Makefile"

    # OpenClash 仓库很大，只取 LuCI 包目录。
    tmp="$pkgdir/.openclash"
    rm -rf "$tmp" "$pkgdir/luci-app-openclash"
    git clone --depth=1 --filter=blob:none --sparse --branch dev \
      https://github.com/vernesong/OpenClash.git "$tmp"
    git -C "$tmp" sparse-checkout set luci-app-openclash
    mv "$tmp/luci-app-openclash" "$pkgdir/luci-app-openclash"
    rm -rf "$tmp"

    replace_package homeproxy https://github.com/immortalwrt/homeproxy.git master
    replace_package_tree passwall-packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git main
    replace_package_tree passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2.git main
    # daed 与 LuCI 前端由当前源码树的 packages/luci feeds 提供。它们与
    # 对应的内核、Go 和 BPF 基础设施同步更新，比覆盖为独立开发分支稳定。
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
