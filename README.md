# OK-Wrt

面向 Qualcomm 与 MediaTek 路由器的多产品线固件构建系统。

> 管理地址：`http://192.168.66.1`　用户名：`root`　密码：`password`
>
> 首次登录后请立即修改管理密码和无线密码。

[下载最新 Release](../../releases/latest) · [查看全部 Release](../../releases) · [版本怎么选](#版本矩阵) · [功能集](#功能集) · [设备支持](#设备支持) · [上游仓库](#上游仓库)

## 版本矩阵

先选择驱动产品线，再选择更新通道；功能集是第三个独立维度。

| 版本 | LTS | Edge |
|---|---|---|
| **Open** | 开源驱动 + 稳定分支 | 开源驱动 + 开发分支 |
| **Pro** | 厂商加速栈 + 稳定分支/验证点 | 厂商加速栈 + 最新验证点 |

- **LTS**：跟随固定稳定分支，变更较少，优先推荐日常使用。Qualcomm Open 暂为例外，原因见[上游仓库](#上游仓库)。
- **Edge**：跟随开发分支，较早获得新内核、新驱动和设备修复，也更可能遇到回归。
- **Open 与 Pro 不建议保留配置互刷**。升级前请备份，切换产品线时建议恢复默认配置。

Release 文件名按 `平台-产品线-通道-功能集-设备` 组织，例如：

```text
qcom-pro-lts-standard-usb-jdcloud_re-cs-02
mtk-open-edge-core-cudy_tr3000-v1
```

## 功能集

| 功能集 | 包含内容 | 设备条件 |
|---|---|---|
| **Core** | LuCI、Firewall4、dnsmasq-full、DDNS、UPnP、ttyd、iperf3、tcpdump 与常用诊断工具 | 所有设备 |
| **Standard** | Core + NetSpeedTest、OpenClash/Mihomo、Tailscale、ZeroTier、Socat、MWAN3 | 所有设备 |
| **Standard USB** | Standard + USB 存储/网卡/串口/4G/5G、Samba4、Diskman、QModem | 仅有 USB 的设备 |
| **Ultra** | Standard USB + Docker、containerd、Dockerman | 仅有 USB 且大内存的设备 |

## 设备支持

当前首批完整构建矩阵共 **28 个变种**。

| 固件设备名 | 产品型号 | 平台 | Open | Pro | USB | Ultra |
|---|---|---|---:|---:|---:|---:|---:|
| `jdcloud_re-cs-02` | 京东云雅典娜 AX6600 / RE-CS-02 | Qualcomm IPQ60xx | 是 | 是 | 是 | 是 |
| `cudy_tr3000-v1` | Cudy TR3000 v1 | MediaTek MT7981 | 是 | 是 | 是 | 否（默认 512 MB） |



## 上游仓库

构建只引用自己的 Fork；每个任务开始时会获取对应原始上游的分支，并在本次工作区同步到最新提交。Fork 与上游提交 SHA 都会写入构建元数据。

| 平台/产品线 | 构建 Fork | 原始上游 | LTS | Edge |
|---|---|---|---|---|
| Qualcomm Open | [Kaucy/immortalwrt](https://github.com/Kaucy/immortalwrt) | [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) | `master`（暂时） | `master` |
| Qualcomm Pro | [Kaucy/LibWrt](https://github.com/Kaucy/LibWrt) | [LiBwrt/openwrt-6.x](https://github.com/LiBwrt/openwrt-6.x) | `25.12-nss` | `main-nss` |
| MediaTek Open | [Kaucy/immortalwrt](https://github.com/Kaucy/immortalwrt) | [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) | `openwrt-25.12` | `master` |
| MediaTek Pro | [Kaucy/immortalwrt-mt798x-rebase](https://github.com/Kaucy/immortalwrt-mt798x-rebase) | [chasey-dev/immortalwrt-mt798x-rebase](https://github.com/chasey-dev/immortalwrt-mt798x-rebase) | `25.12` | `25.12` 最新验证点 |

Qualcomm Pro 则使用 LibWrt 的 NSS 数据面、ECM、加密与 Wi-Fi 加速组件。

MediaTek Pro 使用 SDK/闭源驱动栈。

## 构建与发布

- 每周一 03:00（中国时间，周一 04:00 日本时间）自动同步上游并完整构建。

## 软件包注意事项

内核模块必须使用同一版本、同一产品线构建的软件源。请勿混装其他 OpenWrt/ImmortalWrt 仓库的 `kmod-*`；Open/Pro 的内核 ABI 和驱动依赖也可能不同。

本项目不包含第三方软件本身的额外授权。使用 OpenClash、Tailscale、Docker、厂商驱动或其他组件时，请同时遵守其许可证与所在地区的规定。
