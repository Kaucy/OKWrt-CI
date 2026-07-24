#!/usr/bin/env python3
"""Validate the production catalog and both generated matrix scopes."""

from __future__ import annotations

import csv
import json
import os
import pathlib
import re
import subprocess
from collections import Counter, defaultdict


ROOT = pathlib.Path(__file__).resolve().parents[1]
CATALOG = ROOT / "config/devices.tsv"
HEADER = [
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
]
TARGETS = {
    ("qcom", "qualcommax", "ipq50xx"),
    ("qcom", "qualcommax", "ipq60xx"),
    ("qcom", "qualcommax", "ipq807x"),
    ("qcom", "qualcommbe", "ipq95xx"),
    ("mtk", "mediatek", "filogic"),
}
PIPELINE_SUBTARGETS = {
    ("qcom", "open"): {"ipq50xx", "ipq60xx", "ipq807x", "ipq95xx"},
    ("qcom", "pro"): {"ipq60xx", "ipq807x"},
    ("mtk", "open"): {"filogic"},
    ("mtk", "pro"): {"filogic"},
}
FEATURE_RANK = {"core": 0, "standard": 1, "standard-usb": 2, "ultra": 3}


def fail(message: str) -> None:
    raise SystemExit(message)


with CATALOG.open(encoding="utf-8", newline="") as stream:
    reader = csv.DictReader(stream, delimiter="\t")
    if reader.fieldnames != HEADER:
        fail(f"Unexpected catalog header: {reader.fieldnames}")
    rows = list(reader)

if not rows:
    fail("Device catalog is empty.")

seen: set[tuple[str, ...]] = set()
safe_token = re.compile(r"^[A-Za-z0-9_.+-]+$")
for line, row in enumerate(rows, start=2):
    if any(not row[column].strip() for column in HEADER):
        fail(f"Empty catalog field at line {line}.")
    if (row["platform"], row["target"], row["subtarget"]) not in TARGETS:
        fail(f"Unsupported target at line {line}: {row}")
    if row["edition"] not in {"open", "pro"} or row["channel"] not in {"lts", "edge"}:
        fail(f"Invalid edition/channel at line {line}: {row}")
    if row["max_feature"] not in FEATURE_RANK:
        fail(f"Invalid feature at line {line}: {row['max_feature']}")
    expected_profile = (
        {"kernel-6m", "kernel-large"}
        if row["platform"] == "qcom" and row["subtarget"] == "ipq60xx"
        else {"kernel-default"}
    )
    if row["kernel_profile"] not in expected_profile:
        fail(f"Invalid kernel profile at line {line}: {row}")
    if not safe_token.fullmatch(row["device"]) or not safe_token.fullmatch(row["soc"]):
        fail(f"Unsafe device/SoC token at line {line}: {row}")
    if row["platform"] == "mtk" and row["edition"] == "pro" and row["soc"] not in {"mt7981", "mt7986"}:
        fail(f"MTK Pro contains an unsupported SoC at line {line}: {row['soc']}")
    identity = tuple(
        row[column]
        for column in (
            "platform",
            "target",
            "subtarget",
            "device",
            "edition",
            "channel",
            "kernel_profile",
        )
    )
    if identity in seen:
        fail(f"Duplicate catalog row at line {line}: {identity}")
    seen.add(identity)


def generate(scope: str, platform: str, edition: str) -> list[dict[str, object]]:
    env = dict(os.environ, GITHUB_WORKSPACE=str(ROOT))
    result = subprocess.run(
        [
            str(ROOT / "scripts/generate-matrix.sh"),
            scope,
            "all",
            platform,
            edition,
        ],
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )
    return json.loads(result.stdout)["include"]


for pipeline, required_subtargets in PIPELINE_SUBTARGETS.items():
    platform, edition = pipeline
    expected_rows = [
        row for row in rows if row["platform"] == platform and row["edition"] == edition
    ]
    actual: Counter[tuple[str, ...]] = Counter()
    full = generate("all", platform, edition)
    for item in full:
        devices = str(item["devices"]).split()
        if int(item["device_count"]) != len(devices) or not 1 <= len(devices) <= 25:
            fail(f"Invalid matrix chunk size for {pipeline}: {item}")
        for device in devices:
            actual[
                (
                    str(item["platform"]),
                    str(item["target"]),
                    str(item["subtarget"]),
                    device,
                    str(item["edition"]),
                    str(item["channel"]),
                    str(item["kernel_profile"]),
                )
            ] += 1

    expected = Counter(
        (
            row["platform"],
            row["target"],
            row["subtarget"],
            row["device"],
            row["edition"],
            row["channel"],
            row["kernel_profile"],
        )
        for row in expected_rows
    )
    if actual != expected:
        fail(f"Full matrix does not exactly cover catalog rows for {pipeline}.")

    subtargets = {row["subtarget"] for row in expected_rows}
    if subtargets != required_subtargets:
        fail(f"Unexpected subtarget coverage for {pipeline}: {sorted(subtargets)}")
    if {row["channel"] for row in expected_rows} != {"lts", "edge"}:
        fail(f"Both channels are not present for {pipeline}.")

    expected_groups: dict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    for row in expected_rows:
        group_soc = row["soc"] if pipeline == ("mtk", "pro") else "all"
        expected_groups[
            (
                row["target"],
                row["subtarget"],
                row["channel"],
                group_soc,
                row["kernel_profile"],
            )
        ].append(row)

    smoke = generate("smoke", platform, edition)
    smoke_groups: set[tuple[str, ...]] = set()
    for item in smoke:
        devices = str(item["devices"]).split()
        if len(devices) != 1 or int(item["device_count"]) != 1:
            fail(f"Smoke must select one representative device: {item}")
        group = (
            str(item["target"]),
            str(item["subtarget"]),
            str(item["channel"]),
            str(item["soc"]),
            str(item["kernel_profile"]),
        )
        smoke_groups.add(group)
        candidates = expected_groups.get(group, [])
        selected = next((row for row in candidates if row["device"] == devices[0]), None)
        if selected is None:
            fail(f"Smoke selected a device outside its full group: {item}")
        highest = max(FEATURE_RANK[row["max_feature"]] for row in candidates)
        if FEATURE_RANK[selected["max_feature"]] != highest:
            fail(f"Smoke did not choose a highest-feature representative: {item}")
    if smoke_groups != set(expected_groups):
        fail(f"Smoke group coverage differs from full matrix for {pipeline}.")

readme = (ROOT / "README.md").read_text(encoding="utf-8")
unique_profiles = {
    (row["platform"], row["subtarget"], row["device"]) for row in rows
}
qcom_count = sum(1 for platform, _subtarget, _device in unique_profiles if platform == "qcom")
mtk_count = sum(1 for platform, _subtarget, _device in unique_profiles if platform == "mtk")
summary = f"**{qcom_count} 个 Qualcomm** 与 **{mtk_count} 个 MediaTek**"
if summary not in readme:
    fail(f"README device count is stale; expected: {summary}")

devices_doc = (ROOT / "DEVICES.md").read_text(encoding="utf-8")
for platform, subtarget, device in {
    (row["platform"], row["subtarget"], row["device"]) for row in rows
}:
    marker = f"| {platform}/{subtarget} | `{device}` |"
    if marker not in devices_doc:
        fail(f"DEVICES.md is missing catalog entry: {marker}")

print(
    f"Catalog validation passed: {len(rows)} versioned rows, "
    f"{qcom_count + mtk_count} platform-scoped device profiles."
)
