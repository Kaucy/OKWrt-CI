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

# The closed mt_wifi stack plus the normal LuCI userspace no longer fits the
# fixed 14-15 MiB firmware partitions used by several MT7981 NOR devices.  Core
# is their only eligible feature set, so keep a bootable command-line router
# with vendor Wi-Fi while omitting the web UI, optional acceleration and
# duplicate full-size command-line utilities.  These exclusions are applied
# per profile: larger devices in the same multi-profile build retain the full
# Pro image.
TINY_CORE_EXCLUSIONS = (
    # The package manager is not needed for a fixed-image recovery target and
    # saves the remaining margin on 15 MiB layouts.
    "apk-openssl",
    "luci",
    "luci-ssl",
    "luci-light",
    "luci-base",
    "luci-mod-admin-full",
    "luci-mod-network",
    "luci-mod-status",
    "luci-mod-system",
    "luci-app-firewall",
    "luci-theme-argon",
    "luci-app-argon-config",
    "luci-app-mtwifi-cfg",
    "rpcd-mod-luci",
    "rpcd-mod-rrdns",
    "uhttpd",
    "uhttpd-mod-ubus",
    "ucode-mod-html",
    "curl",
    "wget-ssl",
    "bash",
    "ip-full",
    "ip-bridge",
    "ethtool",
    "kmod-mediatek_hnat",
    "kmod-warp",
    "kmod-ipt-nat",
    # These NOR-only profiles cannot fit both the closed wireless stack and
    # optional WAN/IPv6, RPC or acceleration layers.  Keep IPv4 DHCP/DNS,
    # Firewall4, Dropbear and the vendor Wi-Fi control plane.
    "wpad-openssl",
    "hostapd-common",
    "odhcp6c",
    "odhcpd-ipv6only",
    "ppp",
    "ppp-mod-pppoe",
    "luci-proto-ipv6",
    "luci-proto-ppp",
    "kmod-ppp",
    "kmod-pppoe",
    "kmod-pppox",
    "kmod-mppe",
    "kmod-slhc",
    "rpcd",
    "rpcd-mod-file",
    "rpcd-mod-iwinfo",
    "rpcd-mod-ucode",
    "libiwinfo-data",
    "autocore",
    "kmod-crypto-hw-safexcel",
    "eip197-mini-firmware",
    "kmod-nft-fullcone",
    "kmod-nft-offload",
    "kmod-nf-nathelper",
    "kmod-nf-conntrack6",
    "kmod-nf-log6",
    "kmod-nf-reject6",
    "kmod-ipt-core",
    "kmod-nf-ipt",
    "ca-bundle",
    "ca-certificates",
    "shellsync",
    "dnsmasq-full",
)

TINY_CORE_ADDITIONS = ("dnsmasq",)

# The remaining fixed 14-14.5 MiB NOR layouts still have roughly 1 MiB less
# room than the 15 MiB class.  Their image recipe appends the kernel and rootfs
# directly, so storage helpers, acceleration detection, SMP tuning and online
# fetch support are not required at runtime.  Keep the vendor Wi-Fi control
# plane, IPv4 DNS/DHCP, Firewall4 and Dropbear intact.
MICRO_CORE_EXCLUSIONS = (
    "fitblk",
    "block-mount",
    "mtk-smp",
    "l1util",
    "hnat-detect",
    "procd-ujail",
    "uclient-fetch",
    "libustream-openssl",
)

# Keep this boundary aligned with the fixed-size classification in main().
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
    tiny: set[str] = set()
    micro: set[str] = set()
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
        # 16 MiB is the first layout class where the complete Pro Core fits.
        if image_size is not None and image_size < 16384:
            tiny.add(name)
        # The 15 MiB class fits after the tiny exclusions.  Smaller fixed NOR
        # layouts need the additional non-routing helpers removed.
        if image_size is not None and image_size < 15360:
            micro.add(name)

    compact_exclusions = " ".join(
        f"-{package}" for package in COMPACT_CORE_EXCLUSIONS
    )
    tiny_packages = " ".join(
        (
            *(f"-{package}" for package in TINY_CORE_EXCLUSIONS),
            *TINY_CORE_ADDITIONS,
        )
    )
    micro_exclusions = " ".join(
        f"-{package}" for package in MICRO_CORE_EXCLUSIONS
    )

    def add_compact_exclusions(match: re.Match[str]) -> str:
        name, body = match.group(1), match.group(2)
        if name not in compact or "OKWRT_MTK_PRO_COMPACT_CORE" in body:
            return match.group(0)
        body = body.rstrip() + (
            "\n  # OKWRT_MTK_PRO_COMPACT_CORE: fit the vendor stack on fixed small flash.\n"
            f"  DEVICE_PACKAGES += {compact_exclusions}\n"
        )
        if name in tiny:
            body += (
                "  # OKWRT_MTK_PRO_TINY_CORE: keep vendor Wi-Fi and routing on sub-16 MiB images.\n"
                f"  DEVICE_PACKAGES += {tiny_packages}\n"
            )
        if name in micro:
            body += (
                "  # OKWRT_MTK_PRO_MICRO_CORE: fit direct-layout NOR images below 15 MiB.\n"
                f"  DEVICE_PACKAGES += {micro_exclusions}\n"
            )
        return f"define Device/{name}\n{body}endef"

    text = BLOCK_RE.sub(add_compact_exclusions, text)
    path.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
