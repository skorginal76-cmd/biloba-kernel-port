# Biloba Kernel 5.10.257 Port - GitHub Actions Workflow

## Cihaz
- **Model:** Redmi Note 8 2021 (Biloba)
- **SoC:** MediaTek MT6768
- **Kaynak:** Xiaomi biloba-r-oss (Android 11, Linux 4.14)
- **Hedef:** Linux 5.10.257 Stable

## Dosya Yapisi

```
.github/workflows/
  biloba-5.10-port.yml    # Ana GitHub Actions workflow

configs/
  biloba_5.10_defconfig   # 5.10 uyumlu defconfig

patches/
  0001-fix-kconfig-syntax.patch  # Kconfig syntax duzeltme script'i

scripts/
  01-extract-device-files.sh    # Cihaz dosyalarini cikar
  02-setup-linux-510.sh         # Linux 5.10 stable indir
  03-integrate-files.sh          # Dosyalari entegre et
  04-apply-patches.sh            # Patch'leri uygula
```

## Kurulum

1. Bu dosyalari repo root'una kopyala:
```bash
cp -r biloba-workflow/* /path/to/your/repo/
```

2. Git'e ekle ve push et:
```bash
git add .
git commit -m "Add Biloba 5.10.257 port workflow"
git push origin master
```

3. GitHub Actions sekmesinden workflow'u calistir.

## Cozulen Hatalar

| Hata | Cozum |
|------|-------|
| Disk alani dolu (apt-get update) | Her iki job'da da manuel disk temizligi |
| YAML syntax hatasi (line 234) | `cat << EOF` -> `printf` degisimi |
| `make mrproper` hatasi | `Linux Stable Indir` sonrasi `mrproper` adimi |
| Kconfig `---help---` | Otomatik `help` degisimi |
| Kconfig `prompt redefined` | Duplicate prompt kaldirma |
| Eksik touchscreen Kconfig | Otomatik olusturma |
| `irrx` `choose` -> `choice` | Otomatik duzeltme |

## Bilinen Sinirlamalar

- `CONFIG_MTK_*` driver'lari 5.10 mainline'da yoktur. Vendor patch'leri gerekir.
- Device tree dosyalari (`mt6768.dts`, `biloba.dts`) entegre edilmelidir.
- Build sirasinda MTK driver hatalari alinabilir - bunlar icin ayri patch'ler gerekir.

## Lisans
GPL-2.0
