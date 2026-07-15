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
| Standard | Core + NetSpeedTest、OpenClash/Mihomo、Tailscale、ZeroTier、Socat、MWAN3 |
| Standard USB | Standard + USB 存储、USB 网卡、4G/5G 模组、Samba4、Diskman、QModem |
| Ultra | Standard USB + Docker、containerd、Dockerman；仅适用于有 USB 且大内存设备 |

## 设备对照

| 固件设备名 | 产品型号 | 平台 | USB | Ultra |
|---|---|---|---:|---:|
| `jdcloud_re-cs-02` | 京东云雅典娜 AX6600 / RE-CS-02 | Qualcomm IPQ60xx | 是 | 是 |
| `cudy_tr3000-v1` | Cudy TR3000 v1 | MediaTek MT7981 | 是 | 否（默认） |

## 软件包说明

Release 同时包含每个固件的 `.config`、manifest 和 SHA256 校验文件。内核模块必须使用同一版本、同一产品线构建的软件源，不要混装其他 OpenWrt/ImmortalWrt 仓库中的 `kmod-*`。
EOF
