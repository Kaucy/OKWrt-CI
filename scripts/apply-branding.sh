#!/usr/bin/env bash
set -euo pipefail

topdir="${1:?OpenWrt source directory is required}"
ip="192.168.66.1"
hostname="OK-Wrt"

config_generate="$topdir/package/base-files/files/bin/config_generate"
shadow="$topdir/package/base-files/files/etc/shadow"

sed -i -E "s/192\.168\.[0-9]+\.[0-9]+/$ip/g" "$config_generate"
sed -i -E "s/hostname='[^']*'/hostname='$hostname'/" "$config_generate"

password_hash="$(openssl passwd -6 -salt OKWrt password)"
sed -i "s#^root:[^:]*:#root:$password_hash:#" "$shadow"

# 统一发行版品牌文本。
release_file="$topdir/package/base-files/files/etc/openwrt_release"
if [[ -f "$release_file" ]]; then
  sed -i "s/^DISTRIB_ID=.*/DISTRIB_ID='OK-Wrt'/" "$release_file"
  sed -i "s/^DISTRIB_DESCRIPTION=.*/DISTRIB_DESCRIPTION='OK-Wrt'/" "$release_file"
fi

argon_root="$topdir/package/okwrt/argon"
argon_theme="$(find "$argon_root" -maxdepth 2 -type d -name luci-theme-argon -print -quit)"
argon_config="$(find "$argon_root" -type f -path '*/etc/config/argon' -print -quit)"

if [[ -z "$argon_theme" ]]; then
  echo "Argon theme directory not found" >&2
  exit 1
fi

background="$argon_theme/htdocs/luci-static/argon/img/okwrt-background.svg"
mkdir -p "$(dirname "$background")"
cp "$GITHUB_WORKSPACE/files/okwrt-background.svg" "$background"

# 登录页使用纯抽象渐变背景，不出现人物；字体使用系统圆角无衬线字体。
while IFS= read -r file; do
  sed -i -E \
    -e 's#(/luci-static/argon/img/)?bg[^" ]*\.(jpg|jpeg|png|webp)#/luci-static/argon/img/okwrt-background.svg#g' \
    "$file"
done < <(find "$argon_theme" -type f \( -name '*.ut' -o -name '*.htm' -o -name '*.css' \))

while IFS= read -r css; do
  cat >> "$css" <<'EOF'

/* OK-Wrt brand typography */
html, body, button, input, select, textarea {
  font-family: ui-rounded, "SF Pro Rounded", "Nunito", "Microsoft YaHei UI",
    "Microsoft YaHei", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif !important;
}
EOF
done < <(find "$argon_theme" -type f -name '*.css')

if [[ -n "$argon_config" ]]; then
  sed -i -E \
    -e "s/option online_wallpaper '[^']*'/option online_wallpaper 'none'/" \
    -e "s/option blur '[^']*'/option blur '10'/" \
    "$argon_config"
fi

grep -q '^root:\$6\$OKWrt\$' "$shadow" || {
  echo "Failed to set root password" >&2
  exit 1
}
