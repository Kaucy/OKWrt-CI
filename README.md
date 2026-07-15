# OK-Wrt

面向 Qualcomm 与 MediaTek 路由器的多产品线固件构建系统。

> 管理地址：`http://192.168.66.1`　用户名：`root`　密码：`password`
>
> 首次登录后请立即修改管理密码和无线密码。

[下载最新 Release](../../releases/latest) · [查看全部 Release](../../releases) · [版本怎么选](#版本矩阵) · [功能集](#功能集) · [完整设备目录](DEVICES.md) · [上游仓库](#上游仓库)

## 版本矩阵

先选择驱动产品线，再选择更新通道；功能集是第三个独立维度。

| 版本 | LTS | Edge |
|---|---|---|
| **Open** | 开源驱动 + 稳定分支 | 开源驱动 + 开发分支 |
| **Pro** | 厂商加速栈 + 稳定分支/验证点 | 厂商加速栈 + 最新验证点 |

- **LTS**：跟随固定稳定分支，变更较少，优先推荐日常使用。
- **Edge**：跟随开发分支，较早获得新内核、新驱动和设备修复，也更可能遇到回归。
- **Open 与 Pro 不建议保留配置互刷**。升级前请备份，切换产品线时建议恢复默认配置。

Release 资产按 `目标-子目标-产品线-通道-功能集-分块--上游固件名` 组织，上游固件名保留设备代号，例如：

```text
okwrt-qualcommax-ipq60xx-pro-lts-ultra-part1--immortalwrt-qualcommax-ipq60xx-jdcloud_re-cs-02-squashfs-sysupgrade.bin
okwrt-mediatek-filogic-open-edge-core-part3--immortalwrt-mediatek-filogic-cudy_tr3000-v1-squashfs-sysupgrade.bin
```

## 功能集

| 功能集 | 包含内容 | 设备条件 |
|---|---|---|
| **Core** | LuCI、Firewall4、dnsmasq-full、DDNS、UPnP、ttyd、iperf3、tcpdump 与常用诊断工具 | 所有设备 |
| **Standard** | Core + NetSpeedTest、OpenClash/Mihomo、HomeProxy、PassWall2、daed、Tailscale、ZeroTier、Socat、MWAN3 | ARM64 且固件空间充足的设备 |
| **Standard USB** | Standard + USB 存储/网卡/串口/4G/5G、Samba4、Diskman、QModem | 仅有 USB 的设备 |
| **Ultra** | Standard USB + Docker、containerd、Dockerman | 仅有 USB 且大内存的设备 |

## 设备支持

构建范围固定为以下芯片族，并启用各对应上游分支中现有的全部设备 profile：

- Qualcomm：IPQ50xx、IPQ60xx、IPQ807x/IPQ817x、IPQ95xx。
- MediaTek：MT762x、MT798x（Filogic）。

当前目录合并去重后包含 **98 个 Qualcomm** 与 **805 个 MediaTek** 设备 profile。不同 LTS/Edge、Open/Pro 上游的实际设备集合并不完全相同，准确的设备代号、设备名称、SoC、版本支持与最高功能集统一列在 [DEVICES.md](DEVICES.md)。

CI 按目标、功能集和最多 25 个设备一组生成矩阵，避免“每设备一个 Job”超过 GitHub Actions 矩阵规模。Core 尝试构建范围内所有上游 profile；Standard 及以上只对架构、闪存、USB 和内存条件满足的设备生成。

## 上游仓库

构建只引用自己的 Fork；每个任务开始时会获取对应原始上游的分支，并在本次工作区同步到最新提交。Fork 与上游提交 SHA 都会写入构建元数据。

| 平台/产品线 | 构建 Fork | 原始上游 | LTS | Edge |
|---|---|---|---|---|
| Qualcomm Open | [Kaucy/immortalwrt](https://github.com/Kaucy/immortalwrt) | [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) | `openwrt-25.12` | `master` |
| Qualcomm Pro | [Kaucy/LibWrt](https://github.com/Kaucy/LibWrt) | [LiBwrt/openwrt-6.x](https://github.com/LiBwrt/openwrt-6.x) | `25.12-nss` | `main-nss` |
| MediaTek Open | [Kaucy/immortalwrt](https://github.com/Kaucy/immortalwrt) | [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) | `openwrt-25.12` | `master` |
| MediaTek Pro | [Kaucy/immortalwrt-mt798x-rebase](https://github.com/Kaucy/immortalwrt-mt798x-rebase) | [chasey-dev/immortalwrt-mt798x-rebase](https://github.com/chasey-dev/immortalwrt-mt798x-rebase) | `25.12` | `25.12` 最新验证点 |

Qualcomm Pro 使用 LibWrt 的 NSS 数据面、ECM、加密与 Wi-Fi 加速组件，仅为上游具备 NSS 产品线支持的 IPQ60xx、IPQ807x/IPQ817x 生成 Pro。IPQ50xx 与 IPQ95xx 仅生成 Open。

MediaTek Pro 使用 SDK/闭源驱动栈，目前只为闭源 `mt_wifi` 支持的 MT7981/MT7986 生成；其他 MT798x 与全部 MT762x 仅生成 Open。

## 构建与发布

- 每周一 03:00（中国时间，周一 04:00 日本时间）自动同步上游并完整构建。
- `config/devices.tsv` 是 CI 的设备/版本/功能集数据源，`DEVICES.md` 由同一清单生成。
- 更新上游设备清单时按 `scripts/update-device-catalog.py --help` 提供五个上游工作树路径，再提交两份生成文件。

## 软件包注意事项

内核模块必须使用同一版本、同一产品线构建的软件源。请勿混装其他 OpenWrt/ImmortalWrt 仓库的 `kmod-*`；Open/Pro 的内核 ABI 和驱动依赖也可能不同。

Standard 同时提供多套代理前端和后端，但默认不会同时启用服务。HomeProxy 使用 sing-box；PassWall2 包含 Xray 与 sing-box 核心及 nftables 透明代理组件；daed 包含 LuCI 前端、daed 后端和所需 eBPF/BTF 内核能力。

本项目不包含第三方软件本身的额外授权。使用 OpenClash、HomeProxy、PassWall2、daed、Tailscale、Docker、厂商驱动或其他组件时，请同时遵守其许可证与所在地区的规定。
