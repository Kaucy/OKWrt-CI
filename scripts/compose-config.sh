#!/usr/bin/env bash
set -euo pipefail

topdir="${1:?OpenWrt source directory is required}"
platform="${2:?platform is required}"
edition="${3:?edition is required}"
feature_set="${4:?feature set is required}"

cat "$GITHUB_WORKSPACE/config/platform/$platform.config" \
    "$GITHUB_WORKSPACE/config/common.config" \
    "$GITHUB_WORKSPACE/config/edition/$platform-$edition.config" \
    > "$topdir/.config"

case "$feature_set" in
  core)
    ;;
  standard)
    cat "$GITHUB_WORKSPACE/config/features/standard.config" >> "$topdir/.config"
    ;;
  standard-usb)
    cat "$GITHUB_WORKSPACE/config/features/standard.config" \
        "$GITHUB_WORKSPACE/config/features/standard-usb.config" >> "$topdir/.config"
    ;;
  ultra)
    cat "$GITHUB_WORKSPACE/config/features/standard.config" \
        "$GITHUB_WORKSPACE/config/features/standard-usb.config" \
        "$GITHUB_WORKSPACE/config/features/ultra.config" >> "$topdir/.config"
    ;;
  *)
    echo "Unknown feature set: $feature_set" >&2
    exit 1
    ;;
esac
