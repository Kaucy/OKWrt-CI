# OK-Wrt

面向 Qualcomm 与 MediaTek 路由器的多产品线固件构建系统。所有固件统一使用 Argon 界面、圆角无衬线字体和无人物的抽象登录背景。

> 管理地址：`http://192.168.66.1`　用户名：`root`　密码：`password`
>
> 首次登录后请立即修改管理密码和无线密码。

[下载最新 Release](../../releases/latest) · [查看全部 Release](../../releases) · [版本怎么选](#版本矩阵) · [功能集](#功能集) · [设备支持](#设备支持) · [上游仓库](#上游仓库)

## 版本矩阵

先选择驱动产品线，再选择更新通道；功能集是第三个独立维度。

| 产品线 | LTS | Edge | 适合人群 |
|---|---|---|---|
| **Open** | 开源驱动 + 稳定分支 | 开源驱动 + 开发分支 | 重视开放性、可维护性和标准 OpenWrt 体验 |
| **Pro** | 厂商加速栈 + 稳定分支/验证点 | 厂商加速栈 + 最新验证点 | 需要 Qualcomm NSS 或 MediaTek SDK/闭源驱动能力 |

- **LTS**：跟随固定稳定分支，变更较少，优先推荐日常使用。Qualcomm Open 暂为例外，原因见[上游仓库](#上游仓库)。
- **Edge**：跟随开发分支，较早获得新内核、新驱动和设备修复，也更可能遇到回归。
- **Open 与 Pro 不建议保留配置互刷**。升级前请备份，切换产品线时建议恢复默认配置。

Release 文件名按 `平台-产品线-通道-功能集-设备` 组织，例如：

```text
qcom-pro-lts-standard-usb-jdcloud_re-cs-02
mtk-open-edge-core-cudy_tr3000-v1
```

## 功能集

功能集逐级包含；USB 和内存条件由设备矩阵限制，因此不会为不适用的设备生成无意义变种。

| 功能集 | 包含内容 | 设备条件 |
|---|---|---|
| **Core** | LuCI、Firewall4、dnsmasq-full、DDNS、UPnP、ttyd、iperf3、tcpdump 与常用诊断工具 | 所有设备 |
| **Standard** | Core + NetSpeedTest、OpenClash/Mihomo、Tailscale、ZeroTier、Socat、MWAN3 | 所有设备 |
| **Standard USB** | Standard + USB 存储/网卡/串口/4G/5G、Samba4、Diskman、QModem | 仅有 USB 的设备 |
| **Ultra** | Standard USB + Docker、containerd、Dockerman | 仅有 USB 且大内存的设备 |

## 设备支持

当前首批完整构建矩阵共 **28 个变种**。

| 固件设备名 | 产品型号 | 平台 | Open | Pro | USB | Ultra | 每轮变种数 |
|---|---|---|---:|---:|---:|---:|---:|
| `jdcloud_re-cs-02` | 京东云雅典娜 AX6600 / RE-CS-02 | Qualcomm IPQ60xx | 是 | 是 | 是 | 是 | 16 |
| `cudy_tr3000-v1` | Cudy TR3000 v1 | MediaTek MT7981 | 是 | 是 | 是 | 否（默认 512 MB） | 12 |

每个变种均附带固件、构建 `.config`、软件包 manifest、上游提交信息和 SHA256 校验文件。

## 上游仓库

构建只引用自己的 Fork；每个任务开始时会获取对应原始上游的分支，并在本次工作区同步到最新提交。Fork 与上游提交 SHA 都会写入构建元数据。

| 平台/产品线 | 构建 Fork | 原始上游 | LTS | Edge |
|---|---|---|---|---|
| Qualcomm Open | [Kaucy/immortalwrt](https://github.com/Kaucy/immortalwrt) | [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) | `master`（暂时） | `master` |
| Qualcomm Pro | [Kaucy/LibWrt](https://github.com/Kaucy/LibWrt) | [LiBwrt/openwrt-6.x](https://github.com/LiBwrt/openwrt-6.x) | `25.12-nss` | `main-nss` |
| MediaTek Open | [Kaucy/immortalwrt](https://github.com/Kaucy/immortalwrt) | [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) | `openwrt-25.12` | `master` |
| MediaTek Pro | [Kaucy/immortalwrt-mt798x-rebase](https://github.com/Kaucy/immortalwrt-mt798x-rebase) | [chasey-dev/immortalwrt-mt798x-rebase](https://github.com/chasey-dev/immortalwrt-mt798x-rebase) | `25.12` | `25.12` 最新验证点 |

Qualcomm Open 与 MediaTek Open 共用 ImmortalWrt 源码树，但分别选择 Qualcomm IPQ60xx 与 MediaTek Filogic 目标。Qualcomm Open 保留开源的 `qca-nss-dp` 以太网数据面驱动，同时禁用 NSS 核心加速、ECM、加密和 NSS 固件；Qualcomm Pro 则使用 LibWrt 的 NSS 数据面、ECM、加密与 Wi-Fi 加速组件。

目前 ImmortalWrt 的 `openwrt-25.12` 分支尚未包含 `jdcloud_re-cs-02`，因此 Qualcomm Open 的 LTS 与 Edge 暂时都跟随 `master`。在稳定分支补齐该设备前，两者可能使用相同的源码版本，LTS 标签不代表独立的稳定源码分支。

MediaTek Pro 使用 SDK/闭源驱动栈，因此保留 **Pro** 标识。

## 构建与发布

- 推送构建相关文件到 `main`：构建全部 28 个变种。
- 提交信息包含 `[smoke]`：仅构建两个代表变种，用于在大矩阵前验证流水线。
- 手动运行 `Build OK-Wrt`：可选择 `all`/`smoke` 以及 `all`/`lts`/`edge`。
- 每周一 03:00（中国时间，周一 04:00 日本时间）自动同步上游并完整构建。
- 只有当本轮全部矩阵任务成功时才发布 Release，避免发布缺件版本。

## 软件包注意事项

内核模块必须使用同一版本、同一产品线构建的软件源。请勿混装其他 OpenWrt/ImmortalWrt 仓库的 `kmod-*`；Open/Pro 的内核 ABI 和驱动依赖也可能不同。

本项目不包含第三方软件本身的额外授权。使用 OpenClash、Tailscale、Docker、厂商驱动或其他组件时，请同时遵守其许可证与所在地区的规定。
