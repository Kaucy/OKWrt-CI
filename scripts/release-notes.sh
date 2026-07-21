#!/usr/bin/env bash
set -euo pipefail

output="${1:?output path is required}"
cat > "$output" <<'EOF'
# OK-Wrt 固件

## 登录信息

| 项目 | 默认值 |
|---|---|
| 管理地址 | `http://192.168.66.1` |
| 用户名 | `root` |
| 密码 | `password` |

首次登录后请立即修改管理密码和无线密码。跨 Open/Pro 版本切换时建议不保留配置升级。

## 版本区别

| 版本 | 说明 |
|---|---|
| Open LTS | 标准开源驱动，固定稳定分支 |
| Open Edge | 标准开源驱动，跟随开发分支 |
| Pro LTS | Qualcomm NSS 或 MediaTek SDK 厂商加速栈，稳定分支/锁定点 |
| Pro Edge | Qualcomm NSS 或 MediaTek SDK 厂商加速栈，最新验证点 |

## 功能集

| 功能集 | 软件包与能力 |
|---|---|
| Core | LuCI、Firewall4、dnsmasq-full、DDNS、UPnP、ttyd、iperf3、tcpdump、常用诊断工具 |
| Standard | Core + NetSpeedTest、OpenClash/Mihomo、HomeProxy、PassWall2（Xray + sing-box + nftables）、daed（LuCI + eBPF/BTF）、Tailscale、ZeroTier、Socat、MWAN3 |
| Standard USB | Standard + USB 存储、USB 网卡、4G/5G 模组、Samba4、Diskman、QModem |
| Ultra | Standard USB + Docker、containerd、Dockerman；仅适用于有 USB 且大内存设备 |

## 设备范围

- Qualcomm：IPQ50xx、IPQ60xx、IPQ807x/IPQ817x、IPQ95xx。
- MediaTek：MT798x（Filogic）。

完整的设备代号、设备名、版本与功能集支持见 [设备支持目录](https://github.com/Kaucy/OKWrt-CI/blob/main/DEVICES.md)。Qualcomm/MediaTek、Open/Pro、LTS/Edge 分别发布，避免不同产品线混在同一个 Release。

## 固件文件怎么选

- `core--`、`standard--`、`standard-usb--`、`ultra--` 表示功能集。
- IPQ60xx 文件中的 `kernel-6m--` 表示设备只有 6 MiB 内核分区并使用紧凑内核；`kernel-large--` 表示较大或动态内核分区并保留上游完整内核能力。两类固件不可按文件名互相替换。
- `*-sysupgrade.bin` / `*-sysupgrade.itb`：从兼容的 OpenWrt 系统升级时使用。
- `*-factory.bin` / `*-factory.ubi`：仅在设备安装说明明确要求从原厂系统刷入时使用。
- `.itb` 与 `.bin` 由上游设备 profile 决定，并非每台设备都会同时提供两种格式；不要自行改扩展名或互相转换。
- 每个功能集都有独立 `SHA256SUMS-*.txt`。Release 不再发布 `config.txt`、buildinfo、profiles、内核裸文件、initramfs 或失败日志。

## 软件包说明

构建 artifact 保留 `.config`、manifest 和诊断日志供 CI 验收；面向用户的 Release 只包含可刷写固件及 SHA256 校验文件。内核模块必须使用同一版本、同一产品线构建的软件源，不要混装其他 OpenWrt/ImmortalWrt 仓库中的 `kmod-*`。
EOF
