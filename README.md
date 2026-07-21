# OK-Wrt

面向 Qualcomm 与 MediaTek 路由器的多产品线固件构建系统。

> 管理地址：`http://192.168.66.1`　用户名：`root`　密码：`password`
>
> 首次登录后请立即修改管理密码和无线密码。

[下载 Release](../../releases) · [版本怎么选](#版本矩阵) · [固件文件怎么选](#release-分类与固件格式) · [功能集](#功能集) · [完整设备目录](DEVICES.md) · [上游仓库](#上游仓库)

## 版本矩阵

先选择驱动产品线，再选择更新通道；功能集是第三个独立维度。

| 版本 | LTS | Edge |
|---|---|---|
| **Open** | 开源驱动 + 稳定分支 | 开源驱动 + 开发分支 |
| **Pro** | 厂商加速栈 + 稳定分支/验证点 | 厂商加速栈 + 最新验证点 |

- **LTS**：跟随固定稳定分支，变更较少，优先推荐日常使用。
- **Edge**：跟随开发分支，较早获得新内核、新驱动和设备修复，也更可能遇到回归。
- **Open 与 Pro 不建议保留配置互刷**。升级前请备份，切换产品线时建议恢复默认配置。

## Release 分类与固件格式

Release 按 **平台 + 产品线 + 芯片族 + 通道** 独立发布，例如 `Qualcomm Open · IPQ60xx · LTS`、`MediaTek Pro · Filogic · Edge`，不再把不同芯片族和四条构建线堆在同一个 Release。同一分类使用稳定下载页，每次完整构建会覆盖同名旧资产；Smoke 和不完整构建只保留 Actions artifact，不会污染 Release。Release 内按功能集前缀排序，并保留上游设备代号：

```text
ultra--kernel-6m--immortalwrt-qualcommax-ipq60xx-jdcloud_re-cs-02-squashfs-sysupgrade.bin
standard-usb--kernel-large--immortalwrt-qualcommax-ipq60xx-linksys_mr7500-squashfs-sysupgrade.bin
standard--immortalwrt-mediatek-filogic-cudy_tr3000-v1-squashfs-sysupgrade.bin
standard--immortalwrt-mediatek-filogic-xiaomi_redmi-router-ax6000-ubootmod-squashfs-sysupgrade.itb
```

- `.bin` 和 `.itb` 都会保留；具体格式由设备上游 profile 决定，并非每台设备同时提供两种。
- IPQ60xx 的 `kernel-6m--` 表示 6 MiB 固定内核分区，使用紧凑内核配置；`kernel-large--` 表示更大或动态内核分区，保留上游完整诊断与可选 BPF 能力。该标记来自设备 profile，不能手工改名后混刷。
- `sysupgrade` 用于从兼容 OpenWrt 升级；`factory` 仅用于设备安装说明明确支持的原厂刷入场景。
- `.ubi` 与 `combined.img.gz` 仅在上游将其定义为可刷写 factory/sysupgrade/磁盘镜像时发布。
- Release 只保留可刷写固件和按功能集生成的 `SHA256SUMS`；配置、buildinfo、profiles、裸 kernel、initramfs 和失败日志只留在 Actions artifact 中。

## 功能集

| 功能集 | 包含内容 | 设备条件 |
|---|---|---|
| **Core** | LuCI、Firewall4、dnsmasq-full、DDNS、UPnP、ttyd、iperf3、tcpdump 与常用诊断工具 | 所有设备 |
| **Standard** | Core + NetSpeedTest、OpenClash/Mihomo、HomeProxy、PassWall2、daed、Tailscale、ZeroTier、Socat、MWAN3 | ARM64 且固件空间充足的设备 |
| **Standard USB** | Standard + USB 存储/网卡/串口/4G/5G、Samba4、Diskman、QModem | 具备 USB 的设备 |
| **Ultra** | Standard USB + Docker、containerd、Dockerman | 具备 USB 且大内存的设备 |

## 设备支持

构建范围固定为以下芯片族，并启用各对应上游分支中现有的全部设备 profile：

- Qualcomm：IPQ50xx、IPQ60xx、IPQ807x/IPQ817x、IPQ95xx。
- MediaTek：MT798x（Filogic）。

当前目录合并去重后包含 **98 个 Qualcomm** 与 **191 个 MediaTek** 设备 profile。不同 LTS/Edge、Open/Pro 上游的实际设备集合并不完全相同，准确的设备代号、设备名称、SoC、版本支持与最高功能集统一列在 [DEVICES.md](DEVICES.md)。

CI 按目标、IPQ60xx 内核分区等级和最多 25 个设备一组生成 Bundle 矩阵，避免“每设备、每功能集一个 Job”造成大量重复编译。6 MiB 与大内核分区设备不会进入同一 Bundle：前者使用紧凑内核，后者不受其裁减影响。每个 Bundle 在同一源码树中依次增量构建 Core、Standard、Standard USB、Ultra 中符合设备条件的功能集，复用下载、工具链、内核与软件包编译结果。矩阵生成器会拒绝清单中超出上述芯片族的条目，防止旧清单或误配置扩大构建范围。

## 上游仓库

构建只引用自己的 Fork；每个任务开始时会获取对应原始上游的分支，并在本次工作区同步到最新提交。Fork 与上游提交 SHA 都会写入构建元数据。

| 平台/产品线 | 构建 Fork | 原始上游 | LTS | Edge |
|---|---|---|---|---|
| Qualcomm Open | [Kaucy/immortalwrt](https://github.com/Kaucy/immortalwrt) | [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) | `openwrt-25.12` | `master` |
| Qualcomm Pro | [Kaucy/LibWrt](https://github.com/Kaucy/LibWrt) | [LiBwrt/openwrt-6.x](https://github.com/LiBwrt/openwrt-6.x) | `25.12-nss` | `main-nss` |
| MediaTek Open | [Kaucy/immortalwrt](https://github.com/Kaucy/immortalwrt) | [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) | `openwrt-25.12` | `master` |
| MediaTek Pro | [Kaucy/immortalwrt-mt798x-rebase](https://github.com/Kaucy/immortalwrt-mt798x-rebase) | [chasey-dev/immortalwrt-mt798x-rebase](https://github.com/chasey-dev/immortalwrt-mt798x-rebase) | `25.12` | `25.12` 最新验证点 |

Qualcomm Pro 使用 LibWrt 的 NSS 数据面、ECM、加密与 Wi-Fi 加速组件，仅为上游具备 NSS 产品线支持的 IPQ60xx、IPQ807x/IPQ817x 生成 Pro。IPQ50xx 与 IPQ95xx 仅生成 Open。

MediaTek Pro 使用 SDK/闭源驱动栈，目前只为闭源 `mt_wifi` 支持的 MT7981/MT7986 生成；其他 MT798x 仅生成 Open。

## 构建与发布

构建拆分为四个互不阻塞、可独立重跑的工作流：

| 工作流 | 构建范围 | 每周启动时间（中国时间） |
|---|---|---|
| Build Qualcomm Open | Qualcomm Open LTS/Edge | 周一 03:00 |
| Build Qualcomm Pro | Qualcomm Pro LTS/Edge | 周一 03:15 |
| Build MediaTek Open | MediaTek Open LTS/Edge | 周一 03:30 |
| Build MediaTek Pro | MediaTek Pro LTS/Edge | 周一 03:45 |

- 四个工作流分别按平台、Open/Pro 与 LTS/Edge 发布；某个分片失败不会阻止其他产品线或已完成固件发布。
- 单个 Bundle 中某个高功能集失败时，已经完成的较低功能集仍会上传，便于下载和针对失败变种重试。
- 完整矩阵按设备目标、通道、产品线和 IPQ60xx 内核分区等级动态拆分 Bundle Job。
- `config/devices.tsv` 是 CI 的设备/版本/功能集数据源，`DEVICES.md` 由同一清单生成。
- 更新上游设备清单时按 `scripts/update-device-catalog.py --help` 提供五个上游工作树路径，再提交两份生成文件。

## 软件包注意事项

内核模块必须使用同一版本、同一产品线构建的软件源。请勿混装其他 OpenWrt/ImmortalWrt 仓库的 `kmod-*`；Open/Pro 的内核 ABI 和驱动依赖也可能不同。

Standard 同时提供多套代理前端和后端，但默认不会同时启用服务。HomeProxy 使用 sing-box；PassWall2 包含 Xray 与 sing-box 核心及 nftables 透明代理组件；daed 包含 LuCI 前端、daed 后端和所需 eBPF/BTF 内核能力。

本项目不包含第三方软件本身的额外授权。使用 OpenClash、HomeProxy、PassWall2、daed、Tailscale、Docker、厂商驱动或其他组件时，请同时遵守其许可证与所在地区的规定。
