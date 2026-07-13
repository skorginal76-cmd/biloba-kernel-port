#!/bin/bash
# 01-extract-device-files.sh
# Extracts device-specific files from Xiaomi biloba-r-oss for 5.10 port

set -e

BILOBA_DIR="$1"
OUTPUT_DIR="$2"

if [ -z "$BILOBA_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: $0 <biloba-oss-dir> <output-dir>"
    exit 1
fi

echo "=== Cihaz Dosyalari Cikarma ==="
echo "Kaynak: $BILOBA_DIR"
echo "Hedef: $OUTPUT_DIR"

mkdir -p "$OUTPUT_DIR"

# Device Tree Sources
echo "[1/6] Device Tree dosyalari..."
if [ -d "$BILOBA_DIR/arch/arm64/boot/dts/mediatek" ]; then
    mkdir -p "$OUTPUT_DIR/dts"
    cp -r "$BILOBA_DIR/arch/arm64/boot/dts/mediatek" "$OUTPUT_DIR/dts/"
    echo "  DTS kopyalandi"
fi

# Mediatek Drivers
echo "[2/6] Mediatek driver'lari..."
if [ -d "$BILOBA_DIR/drivers/misc/mediatek" ]; then
    mkdir -p "$OUTPUT_DIR/drivers/misc"
    cp -r "$BILOBA_DIR/drivers/misc/mediatek" "$OUTPUT_DIR/drivers/misc/"
    echo "  MTK drivers kopyalandi"
fi

# Mediatek Include Headers
echo "[3/6] Mediatek header'lari..."
if [ -d "$BILOBA_DIR/drivers/misc/mediatek/include" ]; then
    mkdir -p "$OUTPUT_DIR/drivers/misc/mediatek/include"
    cp -r "$BILOBA_DIR/drivers/misc/mediatek/include" "$OUTPUT_DIR/drivers/misc/mediatek/"
fi

# Sound / Audio
echo "[4/6] Ses driver'lari..."
if [ -d "$BILOBA_DIR/sound/soc/mediatek" ]; then
    mkdir -p "$OUTPUT_DIR/sound/soc"
    cp -r "$BILOBA_DIR/sound/soc/mediatek" "$OUTPUT_DIR/sound/soc/"
fi

# Firmware
echo "[5/6] Firmware dosyalari..."
if [ -d "$BILOBA_DIR/firmware" ]; then
    mkdir -p "$OUTPUT_DIR/firmware"
    cp -r "$BILOBA_DIR/firmware" "$OUTPUT_DIR/"
fi

# Defconfig
echo "[6/6] Defconfig..."
if [ -f "$BILOBA_DIR/arch/arm64/configs/biloba_defconfig" ]; then
    mkdir -p "$OUTPUT_DIR/configs"
    cp "$BILOBA_DIR/arch/arm64/configs/biloba_defconfig" "$OUTPUT_DIR/configs/biloba_4.14_defconfig"
    echo "  Defconfig kopyalandi (referans olarak)"
fi

echo ""
echo "=== Cikarma Tamamlandi ==="
echo "Toplam: $(find "$OUTPUT_DIR" -type f | wc -l) dosya"
