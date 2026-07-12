#!/bin/bash
#===============================================================================
# Script: 01-extract-device-files.sh
# Aciklama: Biloba-r-oss reposundan Redmi Note 8 (2021) cihazina ozel
#           tum dosyalari kategorize sekilde cikarir.
# Kullanim: ./01-extract-device-files.sh <biloba-kaynak> <cikti-dizini>
#===============================================================================
set -euo pipefail

BILOBA_SRC="${1:-}"
OUTPUT="${2:-}"
DEVICE="biloba"
SOC="mt6768"

if [ -z "$BILOBA_SRC" ] || [ -z "$OUTPUT" ]; then
    echo "Kullanim: $0 <biloba-kaynak-dizini> <cikti-dizini>"
    exit 1
fi

if [ ! -d "$BILOBA_SRC/.git" ]; then
    echo "HATA: $BILOBA_SRC gecerli bir git reposu degil!"
    exit 1
fi

mkdir -p "$OUTPUT"
TOTAL=0

log() { echo "[$(date +%H:%M:%S)] $1"; }

count_files() {
    local n=$(find "$1" -type f 2>/dev/null | wc -l)
    TOTAL=$((TOTAL + n))
    echo "$n"
}

#===============================================================================
# 1. DEVICE TREE (DTS/DTB)
#===============================================================================
log "[1/7] Device Tree dosyalari cikariliyor..."
DTS_OUT="$OUTPUT/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_OUT"

cd "$BILOBA_SRC/arch/arm64/boot/dts/mediatek"
cp -v --parents \
    biloba.dts \
    mt6768.dts \
    backlight_${DEVICE}.dtsi \
    touchscreen_${DEVICE}.dtsi \
    cust_${DEVICE}_camera.dtsi \
    cust_mt6768_*.dtsi \
    mt6768_battery_*.dtsi \
    "$DTS_OUT/" 2>/dev/null || true

# Batarya alt dizini
if [ -d "$BILOBA_SRC/arch/arm64/boot/dts/mediatek/bat_setting" ]; then
    mkdir -p "$DTS_OUT/bat_setting"
    cp -v "$BILOBA_SRC/arch/arm64/boot/dts/mediatek/bat_setting/mt6768_"*.dtsi \
        "$DTS_OUT/bat_setting/" 2>/dev/null || true
fi

# DTS Makefile
if [ -f "$BILOBA_SRC/arch/arm64/boot/dts/mediatek/Makefile" ]; then
    cp -v "$BILOBA_SRC/arch/arm64/boot/dts/mediatek/Makefile" "$DTS_OUT/Makefile.orig"
fi

log "  -> $(count_files $DTS_OUT) dosya"

#===============================================================================
# 2. DEFCONFIG
#===============================================================================
log "[2/7] Defconfig cikariliyor..."
CONF_OUT="$OUTPUT/arch/arm64/configs"
mkdir -p "$CONF_OUT"
cp -v "$BILOBA_SRC/arch/arm64/configs/biloba_defconfig" "$CONF_OUT/"
log "  -> $(count_files $CONF_OUT) dosya"

#===============================================================================
# 3. DT BINDINGS (Header'lar)
#===============================================================================
log "[3/7] DT Bindings header'lari cikariliyor..."
BINDINGS=(
    "include/dt-bindings/memory/mt6768-larb-port.h"
    "include/dt-bindings/gce/mt6768-gce.h"
    "include/dt-bindings/pinctrl/mt6768-pinfunc.h"
    "include/dt-bindings/mmc/mt6768-msdc.h"
    "include/dt-bindings/clock/mt6768-clk.h"
)

for f in "${BINDINGS[@]}"; do
    if [ -f "$BILOBA_SRC/$f" ]; then
        outdir="$OUTPUT/$(dirname $f)"
        mkdir -p "$outdir"
        cp -v "$BILOBA_SRC/$f" "$outdir/"
    fi
done
log "  -> $(count_files $OUTPUT/include) dosya"

#===============================================================================
# 4. MEDIATEK PLATFORM DRIVERLARI (drivers/misc/mediatek)
#===============================================================================
log "[4/7] Mediatek platform driver'lari cikariliyor..."
MISC_MTK="$OUTPUT/drivers/misc/mediatek"
mkdir -p "$MISC_MTK"

# Tam mediatek dizinini kopyala (~120 altmodul)
if [ -d "$BILOBA_SRC/drivers/misc/mediatek" ]; then
    cp -r "$BILOBA_SRC/drivers/misc/mediatek"/* "$MISC_MTK/"
fi

# Ayrica Makefile ve Kconfig'leri de al
for f in Makefile Kconfig Kconfig.default; do
    [ -f "$BILOBA_SRC/drivers/misc/mediatek/$f" ] && \
        cp -v "$BILOBA_SRC/drivers/misc/mediatek/$f" "$MISC_MTK/$f.orig"
done

log "  -> $(count_files $MISC_MTK) dosya"

#===============================================================================
# 5. INPUT (Touchscreen & Keyboard)
#===============================================================================
log "[5/7] Input driver'lari cikariliyor..."

# Touchscreen
cp -r "$BILOBA_SRC/drivers/input/touchscreen/mediatek" \
    "$OUTPUT/drivers/input/touchscreen/" 2>/dev/null || true

# Keyboard
cp -r "$BILOBA_SRC/drivers/input/keyboard/mediatek" \
    "$OUTPUT/drivers/input/keyboard/" 2>/dev/null || true

log "  -> $(count_files $OUTPUT/drivers/input) dosya"

#===============================================================================
# 6. POWER / BATTERY / CHARGER
#===============================================================================
log "[6/7] Power management driver'lari cikariliyor..."
cp -r "$BILOBA_SRC/drivers/power/supply_mtk" \
    "$OUTPUT/drivers/power/" 2>/dev/null || true
log "  -> $(count_files $OUTPUT/drivers/power) dosya"

#===============================================================================
# 7. AUDIO, MEMORY, DRM, ETC
#===============================================================================
log "[7/7] Diger mediatek driver'lari cikariliyor..."

# Audio
cp -r "$BILOBA_SRC/sound/soc/mediatek" "$OUTPUT/sound/soc/" 2>/dev/null || true

# Memory (EMI/SMI)
cp -r "$BILOBA_SRC/drivers/memory/mediatek" "$OUTPUT/drivers/memory/" 2>/dev/null || true

# DRM (GPU/Display)
if [ -d "$BILOBA_SRC/drivers/gpu/drm/mediatek" ]; then
    cp -r "$BILOBA_SRC/drivers/gpu/drm/mediatek" "$OUTPUT/drivers/gpu/drm/" 2>/dev/null || true
fi

# IOMMU
if [ -d "$BILOBA_SRC/drivers/iommu/mediatek" ]; then
    cp -r "$BILOBA_SRC/drivers/iommu/mediatek" "$OUTPUT/drivers/iommu/" 2>/dev/null || true
fi

# SPI master
if [ -d "$BILOBA_SRC/drivers/spi/mediatek" ]; then
    cp -r "$BILOBA_SRC/drivers/spi/mediatek" "$OUTPUT/drivers/spi/" 2>/dev/null || true
fi

# PCIe
if [ -d "$BILOBA_SRC/drivers/pci/controller/mediatek" ]; then
    mkdir -p "$OUTPUT/drivers/pci/controller"
    cp -r "$BILOBA_SRC/drivers/pci/controller/mediatek" "$OUTPUT/drivers/pci/controller/" 2>/dev/null || true
fi

# USB
if [ -d "$BILOBA_SRC/drivers/usb/host/mediatek" ]; then
    mkdir -p "$OUTPUT/drivers/usb/host"
    cp -r "$BILOBA_SRC/drivers/usb/host/mediatek" "$OUTPUT/drivers/usb/host/" 2>/dev/null || true
fi

# LED
if [ -d "$BILOBA_SRC/drivers/leds/mediatek" ]; then
    cp -r "$BILOBA_SRC/drivers/leds/mediatek" "$OUTPUT/drivers/leds/" 2>/dev/null || true
fi

# NVDIMM
if [ -d "$BILOBA_SRC/drivers/nvdimm/mediatek" ]; then
    cp -r "$BILOBA_SRC/drivers/nvdimm/mediatek" "$OUTPUT/drivers/nvdimm/" 2>/dev/null || true
fi

log "  -> $(count_files $OUTPUT/sound/soc/mediatek) ses, $(count_files $OUTPUT/drivers/memory/mediatek) bellek dosyasi"

#===============================================================================
# OZET
#===============================================================================
log "=========================================="
log "Cihaz dosyasi cikarma tamamlandi!"
log "Toplam dosya sayisi: $TOTAL"
log "Cikti dizini: $OUTPUT"
log "=========================================="

# Dosya boyutu
du -sh "$OUTPUT" 2>/dev/null || true
