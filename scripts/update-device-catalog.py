#!/usr/bin/env python3
"""Generate config/devices.tsv and DEVICES.md from checked-out upstream trees."""

from __future__ import annotations

import argparse
import collections
import pathlib
import re


TARGETS = (
    ("qcom", "qualcommax", "ipq50xx", "target/linux/qualcommax/image/ipq50xx.mk", False),
    ("qcom", "qualcommax", "ipq60xx", "target/linux/qualcommax/image/ipq60xx.mk", True),
    ("qcom", "qualcommax", "ipq807x", "target/linux/qualcommax/image/ipq807x.mk", True),
    ("qcom", "qualcommbe", "ipq95xx", "target/linux/qualcommbe/image/ipq95xx.mk", False),
    ("mtk", "mediatek", "filogic", "target/linux/mediatek/image/filogic.mk", True),
)

VERSION_COLUMNS = (
    ("open-lts", "Open LTS"),
    ("open-edge", "Open Edge"),
    ("pro-lts", "Pro LTS"),
    ("pro-edge", "Pro Edge"),
)

FEATURE_RANK = {"core": 0, "standard": 1, "standard-usb": 2, "ultra": 3}
FEATURE_LABELS = {
    "core": "Core",
    "standard": "Standard",
    "standard-usb": "Standard USB",
    "ultra": "Ultra",
}

ULTRA_ALLOWLIST = {"jdcloud_re-cs-02"}
STANDARD_USB_ALLOWLIST = {"cudy_tr3000-v1"}


def args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--immortalwrt-lts", required=True, type=pathlib.Path)
    parser.add_argument("--immortalwrt-edge", required=True, type=pathlib.Path)
    parser.add_argument("--libwrt-lts", required=True, type=pathlib.Path)
    parser.add_argument("--libwrt-edge", required=True, type=pathlib.Path)
    parser.add_argument("--mtk-pro", required=True, type=pathlib.Path)
    parser.add_argument("--output-dir", default=".", type=pathlib.Path)
    return parser.parse_args()


def parse_blocks(path: pathlib.Path) -> dict[str, dict[str, str]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    raw: dict[str, str] = {}
    for match in re.finditer(r"^define Device/([^\s]+)\n(.*?)^endef\s*$", text, re.M | re.S):
        raw[match.group(1)] = match.group(2)

    targets = set(re.findall(r"^TARGET_DEVICES\s*\+=\s*(\S+)", text, re.M))
    cache: dict[str, dict[str, str]] = {}

    def resolve(name: str, trail: tuple[str, ...] = ()) -> dict[str, str]:
        if name in cache:
            return dict(cache[name])
        if name in trail:
            return {}
        body = raw.get(name, "")
        values: dict[str, str] = {"body": body}
        parents = re.findall(r"\$\((?:call\s+)?Device/([^),\s]+)", body)
        for parent in parents:
            inherited = resolve(parent, trail + (name,))
            for key, value in inherited.items():
                if key == "body":
                    values["body"] = value + "\n" + values["body"]
                else:
                    values.setdefault(key, value)
        normalized = re.sub(r"\\\n\s*", " ", body)
        for key in (
            "DEVICE_VENDOR",
            "DEVICE_MODEL",
            "DEVICE_VARIANT",
            "DEVICE_DTS",
            "SOC",
            "IMAGE_SIZE",
            "KERNEL_SIZE",
            "DEVICE_PACKAGES",
        ):
            matches = re.findall(rf"^\s*{key}\s*:?=\s*(.*?)\s*$", normalized, re.M)
            if matches:
                values[key] = matches[-1].strip()
        cache[name] = values
        return dict(values)

    return {name: resolve(name) for name in sorted(targets)}


def pretty_name(device: str, values: dict[str, str]) -> str:
    vendor = values.get("DEVICE_VENDOR", "").replace("$", "").strip()
    model = values.get("DEVICE_MODEL", "").replace("$", "").strip()
    variant = values.get("DEVICE_VARIANT", "").replace("$", "").strip()
    parts = [part for part in (vendor, model, variant) if part and "(" not in part[:2]]
    return " ".join(parts) if parts else device.replace("_", " ")


def size_kib(value: str) -> int | None:
    match = re.fullmatch(r"(\d+)([kKmM]?)", value)
    if not match:
        return None
    size = int(match.group(1))
    unit = match.group(2).lower()
    return size * 1024 if unit == "m" else size


def image_kib(values: dict[str, str]) -> int | None:
    return size_kib(values.get("IMAGE_SIZE", ""))


def kernel_profile(subtarget: str, values: dict[str, str]) -> str:
    if subtarget != "ipq60xx":
        return "kernel-default"
    if size_kib(values.get("KERNEL_SIZE", "")) == 6144:
        return "kernel-6m"
    return "kernel-large"


def infer_soc(subtarget: str, device: str, values: dict[str, str]) -> str:
    if values.get("SOC"):
        return values["SOC"]
    haystack = " ".join((values.get("DEVICE_DTS", ""), values.get("body", ""), device))
    patterns = {
        "filogic": r"\b(mt798[1678])(?:[a-z])?\b",
    }
    match = re.search(patterns.get(subtarget, r"$^"), haystack, re.I)
    return match.group(1).lower() if match else subtarget


def max_feature(platform: str, subtarget: str, device: str, values: dict[str, str]) -> str:
    if device in ULTRA_ALLOWLIST:
        return "ultra"
    if device in STANDARD_USB_ALLOWLIST:
        return "standard-usb"

    size = image_kib(values)
    if size is not None and size < 65536:
        return "core"

    body = values.get("body", "") + " " + values.get("DEVICE_PACKAGES", "")
    has_large_storage = size is None or size >= 65536
    has_usb = bool(re.search(r"kmod-usb(?:2|3|-)", body))
    if has_large_storage and has_usb:
        return "standard-usb"
    return "standard" if has_large_storage else "core"


def collect(ns: argparse.Namespace) -> list[dict[str, str]]:
    sources = (
        ("open", "lts", ns.immortalwrt_lts),
        ("open", "edge", ns.immortalwrt_edge),
        ("pro", "lts", ns.libwrt_lts),
        ("pro", "edge", ns.libwrt_edge),
        ("mtk-pro", "lts", ns.mtk_pro),
        ("mtk-pro", "edge", ns.mtk_pro),
    )
    rows: list[dict[str, str]] = []
    for edition_key, channel, root in sources:
        for platform, target, subtarget, relative, pro_capable in TARGETS:
            if edition_key == "open":
                edition = "open"
            elif edition_key == "pro" and platform == "qcom" and pro_capable:
                edition = "pro"
            elif edition_key == "mtk-pro" and platform == "mtk" and subtarget == "filogic":
                edition = "pro"
            else:
                continue
            path = root / relative
            if not path.exists():
                continue
            for device, values in parse_blocks(path).items():
                soc = infer_soc(subtarget, device, values)
                if edition_key == "mtk-pro" and soc not in {"mt7981", "mt7986"}:
                    continue
                rows.append(
                    {
                        "platform": platform,
                        "target": target,
                        "subtarget": subtarget,
                        "device": device,
                        "name": pretty_name(device, values),
                        "soc": soc,
                        "edition": edition,
                        "channel": channel,
                        "max_feature": max_feature(platform, subtarget, device, values),
                        "kernel_profile": kernel_profile(subtarget, values),
                    }
                )
    return sorted(rows, key=lambda row: tuple(row[key] for key in ("platform", "target", "subtarget", "device", "edition", "channel")))


def write_tsv(rows: list[dict[str, str]], output: pathlib.Path) -> None:
    columns = (
        "platform",
        "target",
        "subtarget",
        "device",
        "name",
        "soc",
        "edition",
        "channel",
        "max_feature",
        "kernel_profile",
    )
    lines = ["\t".join(columns)]
    for row in rows:
        lines.append("\t".join(row[column].replace("\t", " ") for column in columns))
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_docs(rows: list[dict[str, str]], output: pathlib.Path) -> None:
    # A profile is identified by platform/subtarget/device.  Display names can
    # legitimately differ in capitalization or wording between LTS and Edge;
    # including the name in the identity duplicates one physical profile.
    merged: dict[tuple[str, str, str], dict[str, object]] = {}
    for row in rows:
        key = (row["platform"], row["subtarget"], row["device"])
        item = merged.setdefault(
            key,
            {
                "name": row["name"],
                "soc": row["soc"],
                "versions": set(),
                "feature": "core",
                "kernel_profiles": set(),
            },
        )
        item["versions"].add(f'{row["edition"]}-{row["channel"]}')
        item["kernel_profiles"].add(row["kernel_profile"])
        if FEATURE_RANK[row["max_feature"]] > FEATURE_RANK[str(item["feature"])]:
            item["feature"] = row["max_feature"]

    grouped: dict[str, list[tuple[tuple[str, str, str], dict[str, object]]]] = collections.defaultdict(list)
    for key, item in merged.items():
        grouped[str(item["feature"])].append((key, item))

    scope_counts = collections.Counter((key[0], key[1]) for key in merged)

    counts = collections.Counter(row["max_feature"] for row in rows)
    lines = [
        "# OK-Wrt 设备与功能集支持",
        "",
        "> 本文件由 `scripts/update-device-catalog.py` 根据各构建上游的设备 profile 生成。CI 使用同源的 `config/devices.tsv`，不要手工修改生成区。",
        "",
        "## 判定规则",
        "",
        "- **Core**：所有纳入范围且在对应上游分支存在的 profile；小闪存设备可能因镜像空间不足被上游跳过。",
        "- **Standard**：ARM64 且镜像空间不小于 64 MiB，或上游未设置固定镜像上限的设备。",
        "- **Standard USB**：满足 Standard，且 profile 明确包含 USB 驱动；个别已知设备由白名单补充。",
        "- **Ultra**：需要 USB、大闪存和已确认的大内存；目前仅对明确验证过硬件规格的设备开放。",
        "- 功能集逐级包含；表格按设备当前允许的最高功能集归类。",
        "- IPQ817x 设备归入上游 `ipq807x` 子目标。IPQ95xx 当前有 IPQ9570/IPQ9574 profile；IPQ9554 仍需等待上游加入具体设备 profile。",
        "- MT798x Open 覆盖 Filogic 上游全部 profile；Pro 闭源 `mt_wifi` 当前仅支持 MT7981/MT7986。",
        "- IPQ60xx 按内核分区拆分构建：`kernel-6m` 使用紧凑内核配置，`kernel-large` 保留上游完整内核能力。",
        "",
        "## 当前设备范围",
        "",
        "| 平台 | 子目标 | 去重设备 profile 数 |",
        "|---|---|---:|",
    ]
    for (platform, subtarget), count in sorted(scope_counts.items()):
        lines.append(f"| {platform} | {subtarget} | {count} |")
    lines.extend([
        "",
        "## 版本标记",
        "",
        "✅ 表示该设备 profile 存在于对应产品线/通道；❌ 表示对应上游当前没有该 profile。",
        "",
        "| 标记 | 含义 |",
        "|---|---|",
        "| Open LTS | 开源驱动稳定分支 |",
        "| Open Edge | 开源驱动开发分支 |",
        "| Pro LTS | NSS/MediaTek SDK 稳定分支或验证点 |",
        "| Pro Edge | NSS/MediaTek SDK 开发分支或最新验证点 |",
        "",
    ])
    for feature in ("ultra", "standard-usb", "standard", "core"):
        entries = sorted(grouped.get(feature, []), key=lambda entry: entry[0])
        lines.extend(
            [
                f'## {FEATURE_LABELS[feature]}（{len(entries)} 个设备 profile）',
                "",
                "| 平台/子目标 | 设备代号 | 设备名 | SoC | 内核分区 | Open LTS | Open Edge | Pro LTS | Pro Edge |",
                "|---|---|---|---|---|:---:|:---:|:---:|:---:|",
            ]
        )
        for (platform, subtarget, device), item in entries:
            versions = item["versions"]
            support = ["✅" if version in versions else "❌" for version, _label in VERSION_COLUMNS]
            safe_name = str(item["name"]).replace("|", "\\|")
            safe_soc = str(item["soc"]).replace("|", "\\|")
            kernel_profiles = ", ".join(sorted(str(value) for value in item["kernel_profiles"]))
            lines.append(
                f"| {platform}/{subtarget} | `{device}` | {safe_name} | {safe_soc} | "
                f"{kernel_profiles} | {' | '.join(support)} |"
            )
        lines.append("")
    output.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    ns = args()
    output = ns.output_dir.resolve()
    (output / "config").mkdir(parents=True, exist_ok=True)
    rows = collect(ns)
    write_tsv(rows, output / "config/devices.tsv")
    write_docs(rows, output / "DEVICES.md")
    print(f"generated {len(rows)} versioned profile rows")


if __name__ == "__main__":
    main()
