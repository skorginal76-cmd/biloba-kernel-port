# Biloba (Redmi Note 8 2021) Kernel 5.10.257 Port Workflow

> **Profesyonel GitHub Actions tabanli otomatik kernel portlama sistemi.**
> Biloba-r-oss (Android 11 tabanli MT6768 kernel) kaynağından cihaza özel dosyaları çıkarıp, upstream Linux 5.10.257 stable üzerine entegre eder ve derler.

## Ozellikler

- **Tam otomatik**: `workflow_dispatch` ile tek tikla calisir
- **Gercek dosya analizi**: Biloba-r-oss reposundaki gercek cihaza özel dosyalari cikarir
- **5.10 uyumluluk**: Kernel API degisiklikleri icin otomatik patch mekanizmasi
- **Dual toolchain**: Clang (Android) ve GCC destegi
- **Cache**: ccache ile hizli art arda derlemeler
- **Artifact**: Derlenmis Image.gz ve DTB dosyalarini otomatik yayinlar

## Calistirma

1. Bu workflow'u iceren repo'yu GitHub'a push edin
2. Actions > Biloba Kernel 5.10.257 Port > `Run workflow`
3. Parametreleri secin (varsayilanlar onerilir)

## Cihaza Özel Cikarilan Dosyalar

| Kategori | Dosyalar |
|----------|----------|
| **Device Tree** | `biloba.dts`, `mt6768.dts`, `cust_biloba_camera.dtsi`, `backlight_biloba.dtsi`, `touchscreen_biloba.dtsi`, `cust_mt6768_*.dtsi`, `mt6768_battery_*.dtsi` |
| **DT Bindings** | `mt6768-larb-port.h`, `mt6768-gce.h`, `mt6768-pinfunc.h`, `mt6768-msdc.h`, `mt6768-clk.h` |
| **Defconfig** | `biloba_defconfig` (456 satir, MT6768 ozellikleri) |
| **Mediatek Drivers** | `drivers/misc/mediatek/` (~120 altmodul: accdet, cameraisp, ccci, dramc, gpu, imgsensor, lcm, leds, pmic, scp, sspm, thermal, vpu, vow, vv ...) |
| **Touchscreen** | `drivers/input/touchscreen/mediatek/` (focaltech, goodix, novatek, himax...) |
| **Power** | `drivers/power/supply_mtk/mediatek/` (battery, charger, gauge) |
| **Audio** | `sound/soc/mediatek/` (audio_scp, audio_ipi, common, mt6660, mt6358, mt6359) |
| **Memory** | `drivers/memory/mediatek/` (emi, smi, m4u) |

## Bilinen Sinirlamalar

- **5.10 upstream MT6768 destegi yoktur**: Tüm SoC destegi out-of-tree Mediatek driver'lariyla saglanir
- **Driver API farkliliklari**: Bazi Mediatek driver'larinin 5.10 API'siyla uyumsuzluklari manuel patch gerektirebilir
- **GKI (Generic Kernel Image)**: Android 12+ GKI gereksinimleri icin ek ayarlar gerekli olabilir
- **Proprietary blob'lar**: Kamera, GPU ve bazı connectivity driver'lari icin halen vendor blob'lari gerekli

## Dizin Yapisi

```
.
├── .github/workflows/biloba-5.10-port.yml   # Ana CI/CD workflow
├── scripts/
│   ├── 01-extract-device-files.sh            # Cihaz dosyalarini cikar
│   ├── 02-setup-linux-510.sh                 # 5.10.257 indir ve hazirla
│   ├── 03-integrate-files.sh                 # Dosyalari entegre et
│   ├── 04-apply-patches.sh                   # Uyumluluk patch'leri uygula
│   └── 05-build.sh                           # Kernel derle
├── patches/
│   └── README.md                             # Manuel patch talimatlari
├── configs/
│   └── biloba_5.10_defconfig                 # 5.10 icin uyarlanmis config
└── README.md                                 # Bu dosya
```

## Gereksinimler

- GitHub Actions (ubuntu-22.04 runner)
- 30GB+ disk alani (maximize-build-space ile otomatik optimize)
- 3 saate kadar build zamani (ccache ile sonraki buildler ~15-30 dk)

## Lisans

GPL-2.0 - Kernel kaynak kodu ile ayni lisans.
