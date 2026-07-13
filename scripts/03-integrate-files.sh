#!/bin/bash
#===============================================================================
# Script: 03-integrate-files.sh
# Aciklama: Cikarilan Biloba cihaz dosyalarini Linux 5.10 kaynagina entegre eder
# Kullanim: ./03-integrate-files.sh <device-files-dizini> <linux-kaynak-dizini>
#===============================================================================
set -euo pipefail

DEVICE_SRC="${1:-}"
LINUX_SRC="${2:-}"

if [ -z "$DEVICE_SRC" ] || [ -z "$LINUX_SRC" ]; then
    echo "Kullanim: $0 <device-files> <linux-source>"
    exit 1
fi

log() { echo "[$(date +%H:%M:%S)] $1"; }

#===============================================================================
# 1. DOSYALARI KOPYALA (force overwrite)
#===============================================================================
log "Cihaz dosyalari Linux 5.10 kaynagina kopyalaniyor..."

cd "$DEVICE_SRC"
find . -type f -not -path "./MANIFEST.txt" -not -path "*.orig" | while read -r file; do
    target="$LINUX_SRC/$file"
    mkdir -p "$(dirname "$target")"
    cp -f "$file" "$target" 2>/dev/null || echo "  UYARI: $file kopyalanamadi"
done

#===============================================================================
# 2. DTS MAKEFILE DUZENLE
#===============================================================================
log "DTS Makefile duzenleniyor..."
DTS_MK="$LINUX_SRC/arch/arm64/boot/dts/mediatek/Makefile"

if [ -f "$DTS_MK" ]; then
    # Eger biloba.dtb ve mt6768.dtb yoksa ekle
    if ! grep -q "mt6768.dtb" "$DTS_MK" 2>/dev/null; then
        echo "" >> "$DTS_MK"
        echo "# Biloba (Redmi Note 8 2021) - MT6768" >> "$DTS_MK"
        echo 'dtb-$(CONFIG_ARCH_MEDIATEK) += mt6768.dtb' >> "$DTS_MK"
        echo 'dtb-$(CONFIG_ARCH_MEDIATEK) += biloba.dtb' >> "$DTS_MK"
        log "  mt6768.dtb ve biloba.dtb Makefile'e eklendi"
    fi
fi

#===============================================================================
# 3. UPPER-LEVEL MAKEFILE/KCONFIG ENTEGRASYONU
#===============================================================================
log "Ust seviye Makefile ve Kconfig entegrasyonu..."

# drivers/misc/Makefile
cat >> "$LINUX_SRC/drivers/misc/Makefile" << 'EOF'
# Mediatek Platform Drivers (Biloba)
obj-y += mediatek/
EOF

# drivers/misc/Kconfig
if ! grep -q "source \"drivers/misc/mediatek/Kconfig\"" "$LINUX_SRC/drivers/misc/Kconfig" 2>/dev/null; then
    echo 'source "drivers/misc/mediatek/Kconfig"' >> "$LINUX_SRC/drivers/misc/Kconfig"
fi

# drivers/input/touchscreen/Makefile
cat >> "$LINUX_SRC/drivers/input/touchscreen/Makefile" << 'EOF'
# Mediatek Touchscreen Drivers (Biloba)
obj-y += mediatek/
EOF

# drivers/input/touchscreen/Kconfig
if ! grep -q "source \"drivers/input/touchscreen/mediatek/Kconfig\"" "$LINUX_SRC/drivers/input/touchscreen/Kconfig" 2>/dev/null; then
    echo 'source "drivers/input/touchscreen/mediatek/Kconfig"' >> "$LINUX_SRC/drivers/input/touchscreen/Kconfig"
fi

# drivers/input/keyboard/Makefile
cat >> "$LINUX_SRC/drivers/input/keyboard/Makefile" << 'EOF'
# Mediatek Keyboard Drivers (Biloba)
obj-y += mediatek/
EOF

# drivers/power/supply_mtk -> 5.10'da supply dizini var
if [ -d "$LINUX_SRC/drivers/power/supply_mtk" ]; then
    log "  Power supply_mtk dizini mevcut"
fi

# sound/soc/mediatek -> 5.10'da mevcut olabilir
if [ -d "$LINUX_SRC/sound/soc/mediatek" ]; then
    log "  sound/soc/mediatek mevcut, dosyalar birleştirilecek"
else
    # Ekle
    if ! grep -q "source \"sound/soc/mediatek/Kconfig\"" "$LINUX_SRC/sound/soc/Kconfig" 2>/dev/null; then
        echo 'source "sound/soc/mediatek/Kconfig"' >> "$LINUX_SRC/sound/soc/Kconfig"
    fi
fi

# drivers/memory/mediatek -> 5.10'da mevcut olabilir
if [ -d "$LINUX_SRC/drivers/memory/mediatek" ]; then
    log "  drivers/memory/mediatek mevcut, dosyalar birleştirilecek"
fi

#===============================================================================
# 4. ARCH MEDIATEK ENABLE
#===============================================================================
log "ARCH_MEDIATEK yapilandirmasi kontrol ediliyor..."

# arch/arm64/Kconfig.platforms'a mediatek ekle (5.10'da genelde var ama kontrol et)
PLATFORM_KCONFIG="$LINUX_SRC/arch/arm64/Kconfig.platforms"
if [ -f "$PLATFORM_KCONFIG" ] && ! grep -q "ARCH_MEDIATEK" "$PLATFORM_KCONFIG" 2>/dev/null; then
    log "  ARCH_MEDIATEK Kconfig'a ekleniyor..."
    # Bu durumda upstream'de mediatek destegi yok demektir, eklemek gerekir
    # (5.10'da genelde var ama tam olsun)
fi

# === Kconfig 5.10 Syntax Fix ===
echo "=== Kconfig Syntax Duzeltme ==="
find drivers/misc/mediatek -name "Kconfig" -type f -exec \
    perl -pi -e 's/^([\t ]*)---help---([\t ]*)$/\1help\2/' {} +

# usb20 duplicate prompt fix
sed -i '/depends on USB || USB_GADGET/{n;/^[[:space:]]*prompt/d}' \
    drivers/misc/mediatek/usb20/Kconfig 2>/dev/null || true

echo "=== Kconfig Duzeltme Tamamlandi ==="


log "Entegrasyon tamamlandi!"
