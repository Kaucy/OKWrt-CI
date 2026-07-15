# OK-Wrt 设备与功能集支持

> 本文件由 `scripts/update-device-catalog.py` 根据各构建上游的设备 profile 生成。CI 使用同源的 `config/devices.tsv`，不要手工修改生成区。

## 判定规则

- **Core**：所有纳入范围且在对应上游分支存在的 profile；小闪存设备可能因镜像空间不足被上游跳过。
- **Standard**：ARM64 且镜像空间不小于 64 MiB，或上游未设置固定镜像上限的设备。
- **Standard USB**：满足 Standard，且 profile 明确包含 USB 驱动；个别已知设备由白名单补充。
- **Ultra**：需要 USB、大闪存和已确认的大内存；目前仅对明确验证过硬件规格的设备开放。
- 功能集逐级包含；表格按设备当前允许的最高功能集归类。
- IPQ817x 设备归入上游 `ipq807x` 子目标。IPQ95xx 当前有 IPQ9570/IPQ9574 profile；IPQ9554 仍需等待上游加入具体设备 profile。
- MT798x Open 覆盖 Filogic 上游全部 profile；Pro 闭源 `mt_wifi` 当前仅支持 MT7981/MT7986。

## 当前设备范围

| 平台 | 子目标 | 去重设备 profile 数 |
|---|---|---:|
| mtk | filogic | 191 |
| qcom | ipq50xx | 16 |
| qcom | ipq60xx | 33 |
| qcom | ipq807x | 47 |
| qcom | ipq95xx | 2 |

## 版本标记

| 标记 | 含义 |
|---|---|
| Open LTS | 开源驱动稳定分支 |
| Open Edge | 开源驱动开发分支 |
| Pro LTS | NSS/MediaTek SDK 稳定分支或验证点 |
| Pro Edge | NSS/MediaTek SDK 开发分支或最新验证点 |

## Ultra（1 个设备 profile）

| 平台/子目标 | 设备代号 | 设备名 | SoC | 版本支持 |
|---|---|---|---|---|
| qcom/ipq60xx | `jdcloud_re-cs-02` | JDCloud RE-CS-02 | ipq6010 | Open Edge, Pro Edge, Pro LTS |

## Standard USB（88 个设备 profile）

| 平台/子目标 | 设备代号 | 设备名 | SoC | 版本支持 |
|---|---|---|---|---|
| mtk/filogic | `acer_predator-w6` | Acer Predator Connect W6 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `acer_predator-w6d` | Acer Predator Connect W6d | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `acer_predator-w6x-stock` | Acer Predator Connect W6x (Stock Layout) | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `acer_predator-w6x-ubootmod` | Acer Predator Connect W6x (OpenWrt U-Boot Layout) | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `airpi_ap3000m` | Airpi AP3000M | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `asiarf_ap7986-003` | AsiaRF AP7986 003 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `asus_rt-ax59u` | ASUS RT-AX59U | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `asus_tuf-ax4200` | ASUS TUF-AX4200 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `asus_tuf-ax4200q` | ASUS TUF-AX4200Q | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `asus_tuf-ax6000` | ASUS TUF-AX6000 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `asus_zenwifi-bt8` | ASUS ZenWiFi BT8 | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `asus_zenwifi-bt8-ubootmod` | ASUS ZenWiFi BT8 U-Boot mod | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `bananapi_bpi-r3` | Bananapi BPi-R3 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `bananapi_bpi-r3-mini` | Bananapi BPi-R3 Mini | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `bananapi_bpi-r4` | Bananapi BPi-R4 | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `bananapi_bpi-r4-lite` | Bananapi BPi-R4 Lite | mt7987 | Open Edge, Open LTS |
| mtk/filogic | `bananapi_bpi-r4-poe` | Bananapi BPi-R4 2.5GE | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `bazis_ax3000wm` | Bazis AX3000WM | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cmcc_rax3000m` | CMCC RAX3000M | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cmcc_rax3000me` | CMCC RAX3000Me | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `comfast_cf-wr632ax` | COMFAST CF-WR632AX | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `comfast_cf-wr632ax-ubootmod` | COMFAST CF-WR632AX | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `confiabits_mt7981` | Confiabits MT7981 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_tr3000-256mb-v1` | Cudy TR3000 256mb v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_tr3000-v1` | Cudy TR3000 v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_tr3000-v1-ubootmod` | Cudy TR3000 v1 (OpenWrt U-Boot layout) | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_wbr3000uax-v1` | Cudy WBR3000UAX v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_wbr3000uax-v1-ubootmod` | Cudy WBR3000UAX v1 (OpenWrt U-Boot layout) | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_wr3000p-v1` | Cudy WR3000P v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_wr3000p-v1-ubootmod` | Cudy WR3000P v1 (OpenWrt U-Boot layout) | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `glinet_gl-mt2500` | GL.iNet GL-MT2500 MaxLinear PHY | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `glinet_gl-mt2500-airoha` | GL.iNet GL-MT2500 Airoha PHY | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `glinet_gl-mt3000` | GL.iNet GL-MT3000 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `glinet_gl-mt3600be` | GL.iNet GL-MT3600BE | mt7987 | Open Edge, Open LTS |
| mtk/filogic | `glinet_gl-mt6000` | GL.iNet GL-MT6000 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `glinet_gl-x3000` | GL.iNet GL-X3000 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `glinet_gl-xe3000` | GL.iNet GL-XE3000 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `globitel_bt-r320` | Globitel BT-R320 | mt7981 | Open Edge |
| mtk/filogic | `huasifei_wh3000-emmc` | Huasifei WH3000 eMMC | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `huasifei_wh3000-pro-emmc` | Huasifei WH3000 Pro eMMC | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `huasifei_wh3000-pro-nand` | Huasifei WH3000 Pro NAND | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `huasifei_wh3000r-nand` | Huasifei WH3000R NAND | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `jiorouter_ax6000-jidu6101` | JioRouter AX6000 JIDU6101 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `keenetic_kn-1812` | Keenetic KN-1812 | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `keenetic_kn-3811` | Keenetic KN-3811 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `mediatek_mt7981-rfb` | MediaTek MT7981 rfb | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `netcore_n60-pro` | Netcore N60 Pro | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `netcraze_nc-1812` | Netcraze NC-1812 | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `netis_nx32u` | netis NX32U | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `nradio_c8-668gl` | NRadio C8-668GL | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `openembed_som7981` | OpenEmbed SOM7981 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `openfi_6c` | OpenFi 6C | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `openwrt_one` | OpenWrt One | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `routerich_ax3000` | Routerich AX3000 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `routerich_ax3000-ubootmod` | Routerich AX3000 (OpenWrt U-Boot layout) | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `routerich_ax3000-v1` | Routerich AX3000 v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `routerich_be7200` | Routerich BE7200 | mt7987 | Open Edge, Open LTS |
| mtk/filogic | `smartrg_sdg-8733` | Adtran SDG-8733 | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `smartrg_sdg-8734` | Adtran SDG-8734 | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `teltonika_rutc50` | Teltonika RUTC50 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tplink_tl-xdr4288` | TP-Link TL-XDR4288 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tplink_tl-xdr6086` | TP-Link TL-XDR6086 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tplink_tl-xdr6088` | TP-Link TL-XDR6088 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tplink_tl-xtr8488` | TP-Link TL-XTR8488 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `unielec_u7981-01-emmc` | Unielec U7981-01 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `unielec_u7981-01-nand` | Unielec U7981-01 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `wavlink_wl-wn536ax6-a` | WAVLINK WL-WN536AX6 Rev a | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `wavlink_wl-wn551x3` | WAVLINK WL-WN551X3 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `wavlink_wl-wnt100x3` | WAVLINK WL-WNT100X3 | mt7981 | Open Edge |
| mtk/filogic | `wavlink_wl-wnt100x3-ubootmod` | WAVLINK WL-WNT100X3 | mt7981 | Open Edge |
| mtk/filogic | `zbtlink_zbt-z8102ax` | Zbtlink ZBT-Z8102AX | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `zbtlink_zbt-z8102ax-v2` | Zbtlink ZBT-Z8102AX-V2 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `zbtlink_zbt-z8106ax-s` | Zbtlink ZBT-Z8106AX-S | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `zbtlink_zbt-z8106ax-t` | Zbtlink ZBT-Z8106AX-T | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `zbtlink_zbt-z8803be` | Zbtlink ZBT-Z8803BE | mt7988 | Open Edge |
| mtk/filogic | `zyxel_ex5601-t0-stock` | Zyxel EX5601-T0 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `zyxel_ex5601-t0-ubootmod` | Zyxel EX5601-T0 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `zyxel_ex5700-telenor` | Zyxel EX5700 (Telenor) | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq50xx | `linksys_mr5500` | Linksys MR5500 | ipq5018 | Open Edge, Open LTS |
| qcom/ipq60xx | `linksys_mr7350` | Linksys MR7350 | ipq6000 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq60xx | `linksys_mr7500` | Linksys MR7500 | ipq6018 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `arcadyan_aw1000` | Arcadyan AW1000 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `inseego_fg2000` | Inseego Fg2000 | ipq8072 | Pro Edge, Pro LTS |
| qcom/ipq807x | `redmi_ax6` | Redmi AX6 | ipq8071 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `redmi_ax6-stock` | Redmi AX6 | ipq8071 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `tplink_deco-x80-5g` | TP-Link Deco X80-5G | ipq8074 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `xiaomi_ax3600` | Xiaomi AX3600 | ipq8071 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `xiaomi_ax3600-stock` | Xiaomi AX3600 | ipq8071 | Open Edge, Open LTS, Pro Edge, Pro LTS |

## Standard（159 个设备 profile）

| 平台/子目标 | 设备代号 | 设备名 | SoC | 版本支持 |
|---|---|---|---|---|
| mtk/filogic | `abt_asr3000` | ABT ASR3000 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `acelink_ew-7886cax` | Acelink EW-7886CAX | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `acer_vero-w6m` | Acer Connect Vero W6m | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `arcadyan_mozart` | Arcadyan Mozart | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `asus_rt-ax52` | ASUS RT-AX52 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `asus_rt-ax57m` | ASUS RT-AX57M | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `buffalo_wsr-3000ax4p` | BUFFALO WSR-3000AX4P | mt7981 | Open Edge |
| mtk/filogic | `cetron_ct3003-ubootmod` | Cetron CT3003 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cmcc_a10-stock` | CMCC A10 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cmcc_a10-ubootmod` | CMCC A10 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `comfast_cf-e393ax` | COMFAST CF-E393AX | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `comfast_cf-xr186` | COMFAST CF-XR186 | mt7981 | Open Edge |
| mtk/filogic | `creatlentem_clt-r30b1` | CreatLentem CLT-R30B1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `creatlentem_clt-r30b1-112m` | CreatLentem CLT-R30B1 112M | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `creatlentem_clt-r30b1-ubi` | CreatLentem CLT-R30B1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_ap3000-v1` | Cudy AP3000 v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_ap3000outdoor-v1` | Cudy AP3000 Outdoor v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_ap3000wall-v1` | Cudy AP3000 Wall v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_m3000-v1` | Cudy M3000 v1/v2 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_m3000-v1-ubootmod` | Cudy M3000 v1/v2 (OpenWrt U-Boot layout) | mt7981 | Open Edge |
| mtk/filogic | `cudy_m3000-v2-yt8821` | Cudy M3000 v2 with Motorcomm YT8821 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_m3000-v2-yt8821-ubootmod` | Cudy M3000 v2 with Motorcomm YT8821 (OpenWrt U-Boot layout) | mt7981 | Open Edge |
| mtk/filogic | `cudy_wr3000e-v1` | Cudy WR3000E v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_wr3000e-v1-ubootmod` | Cudy WR3000E v1 (OpenWrt U-Boot layout) | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_wr3000h-v1` | Cudy WR3000H v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_wr3000h-v1-ubootmod` | Cudy WR3000H v1 (OpenWrt U-Boot layout) | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_wr3000s-v1` | Cudy WR3000S v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_wr3000s-v1-ubootmod` | Cudy WR3000S v1 (OpenWrt U-Boot layout) | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `edgecore_eap111` | Edgecore EAP111 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `elecom_wrc-x3000gs3` | ELECOM WRC-X3000GS3 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `elecom_wrc-x6000gsd` | ELECOM WRC-X6000GSD | mt7986 | Open Edge |
| mtk/filogic | `elecom_wrc-x6000qs` | ELECOM WRC-X6000QS | mt7986 | Open Edge |
| mtk/filogic | `h3c_magic-nx30-pro` | H3C Magic NX30 Pro | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `imou_hx21` | Imou HX21 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `jcg_q30-pro` | JCG Q30 PRO | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `jdcloud_re-cp-03` | JDCloud RE-CP-03 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `keenetic_kap-630` | Keenetic KAP-630 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `keenetic_kn-3711` | Keenetic KN-3711 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `keenetic_kn-3911` | Keenetic KN-3911 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `konka_komi-a31` | Konka KOMI A31 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `livinet_li320` | Livinet Li320 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `livinet_zr-3020` | Livinet ZR-3020 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `livinet_zr-3020-ubootmod` | Livinet ZR-3020 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `mediatek_mt7986a-rfb-nand` | MediaTek MT7986 rfba AP (NAND) | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `mediatek_mt7986b-rfb` | MediaTek MTK7986 rfbb AP | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `mediatek_mt7987a-rfb` | MediaTek MT7987A rfb | mt7987 | Open Edge, Open LTS |
| mtk/filogic | `mediatek_mt7988a-rfb` | MediaTek MT7988A rfb | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `mercusys_mr80x-v3` | MERCUSYS MR80X v3 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `mercusys_mr85x` | MERCUSYS MR85X | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `mercusys_mr90x-v1-ubi` | MERCUSYS MR90X v1 (UBI) | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `netcore_n60` | Netcore N60 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `netcraze_nap-630` | Netcraze NAP-630 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `netgear_eax17` | NETGEAR EAX17 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `netis_eap930-v1` | netis EAP930 V1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `netis_nx30v2` | netis NX30 V2 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `netis_nx31` | netis NX31 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `nokia_ea0326gmp` | Nokia EA0326GMP | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `qihoo_360t7` | Qihoo 360T7 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `qihoo_360t7-ubi` | Qihoo 360T7 (UBI) | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `ruijie_rg-x60` | Ruijie RG-X60 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `ruijie_rg-x60-pro` | Ruijie RG-X60 Pro | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `smartrg_sdg-8612` | Adtran SDG-8612 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `smartrg_sdg-8614` | Adtran SDG-8614 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `smartrg_sdg-8622` | Adtran SDG-8622 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `smartrg_sdg-8632` | Adtran SDG-8632 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `smartrg_sdg-8733a` | Adtran SDG-8733A | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `snr_snr-cpe-ax2` | SNR SNR-CPE-AX2 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tenda_be12-pro` | Tenda BE12 Pro | mt7987 | Open Edge |
| mtk/filogic | `tplink_f65-v1` | TP-Link F65 v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tplink_tl-7dr7230-v1` | TP-Link TL-7DR7230 v1 | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `tplink_tl-7dr7230-v2` | TP-Link TL-7DR7230 v2 | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `tplink_tl-7dr7250-v1` | TP-Link TL-7DR7250 v1 | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `ubnt_unifi-6-plus` | Ubiquiti UniFi U6+ | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `wavlink_wl-wn586x3b` | WAVLINK WL-WN586X3B | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `xiaomi_mi-router-ax3000t` | Xiaomi Mi Router AX3000T | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `xiaomi_mi-router-ax3000t-ubootmod` | Xiaomi Mi Router AX3000T | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `xiaomi_mi-router-wr30u-stock` | Xiaomi Mi Router WR30U | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `xiaomi_mi-router-wr30u-ubootmod` | Xiaomi Mi Router WR30U | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `xiaomi_redmi-router-ax6000-stock` | Xiaomi Redmi Router AX6000 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `xiaomi_redmi-router-ax6000-ubootmod` | Xiaomi Redmi Router AX6000 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `zbtlink_zbt-z8103ax` | Zbtlink ZBT-Z8103AX | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `zbtlink_zbt-z8103ax-c` | Zbtlink ZBT-Z8103AX-C | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `zyxel_wx5600-t0-ubootmod` | Zyxel WX5600-T0 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq50xx | `glinet_gl-b3000` | GL.iNet GL-B3000 | ipq5018 | Open Edge, Open LTS |
| qcom/ipq50xx | `linksys_mx2000` | Linksys MX2000 | ipq5018 | Open Edge, Open LTS |
| qcom/ipq50xx | `linksys_mx5500` | Linksys MX5500 | ipq5018 | Open Edge, Open LTS |
| qcom/ipq50xx | `linksys_spnmx56` | Linksys SPNMX56 | ipq5018 | Open Edge, Open LTS |
| qcom/ipq50xx | `xiaomi_ax6000` | Xiaomi AX6000 | ipq5018 | Open Edge, Open LTS |
| qcom/ipq50xx | `xiaomi_redmi-ax5400` | Xiaomi Redmi AX5400 | ipq5018 | Open Edge |
| qcom/ipq50xx | `yuncore_ax830` | Yuncore AX830 | ipq5018 | Open Edge, Open LTS |
| qcom/ipq50xx | `yuncore_ax850` | Yuncore AX850 | ipq5018 | Open Edge, Open LTS |
| qcom/ipq50xx | `zyxel_scr50axe` | Zyxel SCR50AXE | ipq5018 | Open Edge, Open LTS |
| qcom/ipq60xx | `alfa-network_ap120c-ax` | ALFA Network AP120C-AX | ipq6000 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq60xx | `anysafe_e1` | AnySafe E1 | ipq6010 | Pro Edge, Pro LTS |
| qcom/ipq60xx | `cambiumnetworks_xe3-4` | Cambium Networks XE3-4 | ipq6010 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq60xx | `cmiot_ax18` | CMIOT AX18 | ipq6000 | Pro Edge, Pro LTS |
| qcom/ipq60xx | `glinet_gl-ax1800` | GL.iNet GL-AX1800 | ipq6000 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq60xx | `glinet_gl-axt1800` | GL.iNet GL-AXT1800 | ipq6000 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq60xx | `jdcloud_re-cs-07` | JDCloud RE-CS-07 | ipq6010 | Open Edge, Pro Edge, Pro LTS |
| qcom/ipq60xx | `jdcloud_re-ss-01` | JDCloud RE-SS-01 | ipq6000 | Open Edge, Pro Edge, Pro LTS |
| qcom/ipq60xx | `kt_ar06-012h` | KT AR06-012H | ipq6000 | Pro Edge, Pro LTS |
| qcom/ipq60xx | `lg_gapd-7500` | LG GAPD-7500 | ipq6000 | Pro Edge, Pro LTS |
| qcom/ipq60xx | `link_nn6000-v1` | Link NN6000 v1 | ipq6000 | Open Edge, Pro Edge, Pro LTS |
| qcom/ipq60xx | `link_nn6000-v2` | Link NN6000 v2 | ipq6000 | Open Edge, Pro Edge, Pro LTS |
| qcom/ipq60xx | `netgear_rbr350` | Netgear RBR350 | ipq6018 | Open Edge, Pro Edge |
| qcom/ipq60xx | `netgear_rbs350` | Netgear RBS350 | ipq6018 | Open Edge, Pro Edge |
| qcom/ipq60xx | `netgear_wax214` | Netgear WAX214 | ipq6010 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq60xx | `netgear_wax610` | Netgear WAX610 | ipq6010 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq60xx | `netgear_wax610y` | Netgear WAX610Y | ipq6010 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq60xx | `qihoo_360v6` | Qihoo 360V6 | ipq6000 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq60xx | `redmi_ax5` | Redmi AX5 | ipq6000 | Pro Edge, Pro LTS |
| qcom/ipq60xx | `redmi_ax5-jdcloud` | Redmi AX5 JDCloud | ipq6000 | Pro Edge, Pro LTS |
| qcom/ipq60xx | `tplink_eap610-outdoor` | TP-Link EAP610-Outdoor | ipq6018 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq60xx | `tplink_eap620-hd-v3` | TP-Link EAP620 HD v3 | ipq6018 | Open Edge, Pro Edge |
| qcom/ipq60xx | `tplink_eap623-outdoor-hd-v1` | TP-Link EAP623-Outdoor HD v1 | ipq6018 | Open Edge, Pro Edge |
| qcom/ipq60xx | `tplink_eap623od-hd-v1` | TP-Link EAP623-Outdoor HD v1 | ipq6018 | Open LTS, Pro LTS |
| qcom/ipq60xx | `tplink_eap625-outdoor-hd-v1` | TP-Link EAP625-Outdoor HD v1 | ipq6018 | Open Edge, Pro Edge |
| qcom/ipq60xx | `tplink_eap625-outdoor-hd-v1` | TP-Link EAP625-Outdoor HD v1 and v1.6 | ipq6018 | Open LTS, Pro LTS |
| qcom/ipq60xx | `xiaomi_ax1800` | Xiaomi AX1800 | ipq6000 | Pro Edge, Pro LTS |
| qcom/ipq60xx | `yuncore_fap650` | Yuncore FAP650 | ipq6018 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq60xx | `zn_m2` | ZN M2 | ipq6000 | Pro Edge, Pro LTS |
| qcom/ipq807x | `aliyun_ap8220` | Aliyun AP8220 | ipq8071 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `asus_rt-ax89x` | Asus RT-AX89X | ipq8074 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `buffalo_wxr-5950ax12` | Buffalo WXR-5950AX12 | ipq8074 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `cmcc_rm2-6` | CMCC RM2-6 | ipq8070 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `compex_wpq873` | Compex WPQ873 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `dynalink_dl-wrx36` | Dynalink DL-WRX36 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `edgecore_eap102` | Edgecore EAP102 | ipq8071 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `edimax_cax1800` | Edimax CAX1800 | ipq8070 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `linksys_homewrk` | Linksys HomeWRK | ipq8174 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `linksys_mx4200v1` | Linksys MX4200 v1 | ipq8174 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `linksys_mx4200v2` | Linksys MX4200 v2 | ipq8174 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `linksys_mx4300` | Linksys MX4300 | ipq8174 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `linksys_mx5300` | Linksys MX5300 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `linksys_mx8500` | Linksys MX8500 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `netgear_rax120v2` | Netgear RAX120v2 | ipq8074 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `netgear_rbr750` | Netgear RBR750 | ipq8074 | Open Edge, Pro Edge |
| qcom/ipq807x | `netgear_rbs750` | Netgear RBS750 | ipq8074 | Open Edge, Pro Edge |
| qcom/ipq807x | `netgear_sxr80` | Netgear SXR80 | ipq8074 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `netgear_sxs80` | Netgear SXS80 | ipq8074 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `netgear_wax218` | Netgear WAX218 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `netgear_wax620` | Netgear WAX620 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `netgear_wax630` | Netgear WAX630 | ipq8074 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `prpl_haze` | prpl Foundation Haze | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `qnap_301w` | QNAP 301w | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `spectrum_sax1v1k` | Spectrum SAX1V1K | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `swaiot_s10sky` | Swaiot S10-SKY | ipq8071 | Pro Edge |
| qcom/ipq807x | `tcl_linkhub-hh500v` | TCL LINKHUB HH500V | ipq8072 | Open Edge, Pro Edge |
| qcom/ipq807x | `tplink_eap620hd-v1` | TP-Link EAP620 HD v1 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `tplink_eap660hd-v1` | TP-Link EAP660 HD v1 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `verizon_cr1000a` | Verizon CR1000A | ipq8072 | Pro Edge, Pro LTS |
| qcom/ipq807x | `xiaomi_ax9000` | Xiaomi AX9000 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `xiaomi_ax9000-stock` | Xiaomi AX9000 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `yuncore_ax880` | Yuncore AX880 | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `zbtlink_zbt-z800ax` | Zbtlink ZBT-Z800AX | ipq8072 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `zte_mf269` | ZTE MF269 | ipq8071 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `zte_mf269-stock` | ZTE MF269 | ipq8071 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `zyxel_nbg7815` | ZYXEL NBG7815 | ipq8074 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq95xx | `8devices_kiwi-dvk` | 8devices Kiwi-DVK | ipq9570 | Open Edge, Open LTS |

## Core（41 个设备 profile）

| 平台/子目标 | 设备代号 | 设备名 | SoC | 版本支持 |
|---|---|---|---|---|
| mtk/filogic | `alwaylink_m01k43` | AlwayLink M01K43 | mt7981 | Open Edge |
| mtk/filogic | `buffalo_wsr-6000ax8` | Buffalo WSR-6000AX8 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cetron_ct3003` | Cetron CT3003 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_re3000-v1` | Cudy RE3000 v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `cudy_wr3000-v1` | Cudy WR3000 v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `dlink_aquila-pro-ai-e30-a1` | D-Link AQUILA PRO AI E30 A1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `dlink_aquila-pro-ai-m30-a1` | D-Link AQUILA PRO AI M30 A1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `dlink_aquila-pro-ai-m60-a1` | D-Link AQUILA PRO AI M60 A1 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `gatonetworks_gdsp` | GatoNetworks gdsp | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `iptime_ax3000m` | ipTIME AX3000M | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `iptime_ax3000q` | ipTIME AX3000Q | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `iptime_ax3000se` | ipTIME AX3000SE | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `iptime_ax3000sm` | ipTIME AX3000SM | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `iptime_ax7800m-6e` | ipTIME AX7800M-6E | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `kebidumei_ax3000-u22` | Kebidumei AX3000-U22 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `mercusys_mr90x-v1` | MERCUSYS MR90X v1 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `netgear_wax220` | NETGEAR WAX220 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tenbay_wr3000k` | Tenbay WR3000K | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `totolink_x6000r` | TOTOLINK X6000R | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tplink_archer-ax80-v1` | TP-Link Archer AX80 v1 | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tplink_archer-ax80-v1-eu` | TP-Link Archer AX80 v1 (EU) | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tplink_be450` | TP-Link BE450 | mt7988 | Open Edge, Open LTS |
| mtk/filogic | `tplink_eap683-lr` | TP-Link EAP683-LR | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tplink_fr365-v1` | TP-Link FR365 v1 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `tplink_re6000xd` | TP-Link RE6000XD | mt7986 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `wavlink_wl-wn573hx3` | WAVLINK WL-WN573HX3 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `wavlink_wl-wn586x3` | WAVLINK WL-WN586X3 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `widelantech_wap430x` | Widelantech WAP430X | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `yuncore_ax835` | YunCore AX835 | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| mtk/filogic | `zyxel_nwa50ax-pro` | Zyxel NWA50AX Pro | mt7981 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq50xx | `cmcc_mr3000d-ci` | CMCC MR3000D-CI | ipq5018 | Open Edge, Open LTS |
| qcom/ipq50xx | `cmcc_pz-l8` | CMCC PZ-L8 | ipq5018 | Open Edge, Open LTS |
| qcom/ipq50xx | `elecom_wrc-x3000gs2` | ELECOM WRC-X3000GS2 | ipq5018 | Open Edge, Open LTS |
| qcom/ipq50xx | `elecom_wrc-x3000gst2` | ELECOM WRC-X3000GST2 | ipq5018 | Open Edge |
| qcom/ipq50xx | `iodata_wn-dax3000gr` | I-O DATA WN-DAX3000GR | ipq5018 | Open Edge, Open LTS |
| qcom/ipq50xx | `linksys_mx6200` | Linksys MX6200 | ipq5018 | Open Edge, Open LTS |
| qcom/ipq60xx | `8devices_mango-dvk` | 8devices Mango-DVK | ipq6010 | Open Edge, Open LTS, Pro Edge, Pro LTS |
| qcom/ipq807x | `zyxel_nwa110ax` | Zyxel NWA110AX | ipq8070 | Open Edge, Pro Edge |
| qcom/ipq807x | `zyxel_nwa210ax` | ZYXEL NWA210AX | ipq8071 | Open LTS, Pro LTS |
| qcom/ipq807x | `zyxel_nwa210ax` | Zyxel NWA210AX | ipq8071 | Open Edge, Pro Edge |
| qcom/ipq95xx | `qcom_rdp433` | Qualcomm Technologies, Inc. RDP433 AP-AL02-C4 | ipq9574 | Open Edge, Open LTS |
