#!/usr/bin/env python3
"""Adapt Filogic profiles before configuring the closed MediaTek wireless stack."""

from __future__ import annotations

import pathlib
import re
import sys


OPEN_WIFI_PACKAGES = (
    "kmod-mt7915e",
    "kmod-mt7916-firmware",
    "kmod-mt7981-firmware",
    "kmod-mt7986-firmware",
    "mt7981-wo-firmware",
    "mt7986-wo-firmware",
)

# The vendor driver is substantially larger than mt76. Keep the router, LuCI,
# firewall, DNS, PPP and Argon essentials on fixed sub-32 MiB images, while
# dropping optional diagnostics and convenience applications.
COMPACT_CORE_EXCLUSIONS = (
    "btop",
    "htop",
    "iperf3",
    "tcpdump",
    "nano",
    "openssh-sftp-server",
    "luci-app-package-manager",
    "luci-app-ttyd",
    "luci-i18n-ttyd-zh-cn",
    "luci-app-upnp",
    "luci-i18n-upnp-zh-cn",
    "luci-app-ddns",
    "luci-i18n-ddns-zh-cn",
    "luci-app-wol",
    "luci-i18n-wol-zh-cn",
)

BLOCK_RE = re.compile(r"^define Device/([^\s]+)\n(.*?)^endef\s*$", re.M | re.S)


def assignment(body: str, key: str) -> str:
    normalized = re.sub(r"\\\n[ \t]*", " ", body)
    matches = re.findall(
        rf"^[ \t]*{re.escape(key)}[ \t]*:?=[ \t]*(.*)$",
        normalized,
        re.M,
    )
    return matches[-1].strip() if matches else ""


def size_kib(value: str) -> int | None:
    match = re.fullmatch(r"(\d+)([kKmM]?)", value)
    if not match:
        return None
    value_kib = int(match.group(1))
    return value_kib * 1024 if match.group(2).lower() == "m" else value_kib


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} FILOGIC_MK", file=sys.stderr)
        return 2

    path = pathlib.Path(sys.argv[1])
    text = path.read_text(encoding="utf-8")

    # Device profiles must not pull mt76 modules or firmware into a build that
    # deliberately replaces them with mt_wifi.
    for package in OPEN_WIFI_PACKAGES:
        text = re.sub(
            rf"(?<![A-Za-z0-9_-]){re.escape(package)}(?![A-Za-z0-9_-])",
            "",
            text,
        )

    blocks = {match.group(1): match.group(2) for match in BLOCK_RE.finditer(text)}
    cache: dict[str, dict[str, str]] = {}

    def resolve(name: str, trail: tuple[str, ...] = ()) -> dict[str, str]:
        if name in cache:
            return dict(cache[name])
        if name in trail:
            return {}
        body = blocks.get(name, "")
        values: dict[str, str] = {"body": body}
        for parent in re.findall(r"\$\((?:call\s+)?Device/([^),\s]+)", body):
            inherited = resolve(parent, trail + (name,))
            for key, value in inherited.items():
                if key == "body":
                    values["body"] = value + "\n" + values["body"]
                else:
                    values.setdefault(key, value)
        for key in ("DEVICE_DTS", "IMAGE_SIZE"):
            value = assignment(body, key)
            if value:
                values[key] = value
        cache[name] = values
        return dict(values)

    compact: set[str] = set()
    for name in blocks:
        values = resolve(name)
        haystack = " ".join(
            (name, values.get("DEVICE_DTS", ""), values.get("body", ""))
        )
        if not re.search(r"\bmt798[16][a-z]?\b", haystack, re.I):
            continue
        image_size = size_kib(values.get("IMAGE_SIZE", ""))
        if image_size is not None and image_size < 32768:
            compact.add(name)

    exclusions = " ".join(f"-{package}" for package in COMPACT_CORE_EXCLUSIONS)

    def add_compact_exclusions(match: re.Match[str]) -> str:
        name, body = match.group(1), match.group(2)
        if name not in compact or "OKWRT_MTK_PRO_COMPACT_CORE" in body:
            return match.group(0)
        body = body.rstrip() + (
            "\n  # OKWRT_MTK_PRO_COMPACT_CORE: fit the vendor stack on fixed small flash.\n"
            f"  DEVICE_PACKAGES += {exclusions}\n"
        )
        return f"define Device/{name}\n{body}endef"

    text = BLOCK_RE.sub(add_compact_exclusions, text)
    path.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
