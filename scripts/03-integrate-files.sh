#!/bin/bash
# 03-integrate-files.sh
# Integrates Biloba device files into Linux 5.10 stable

set -e

DEVICE_DIR="$1"
LINUX_DIR="$2"

if [ -z "$DEVICE_DIR" ] || [ -z "$LINUX_DIR" ]; then
    echo "Usage: $0 <device-files-dir> <linux-stable-dir>"
    exit 1
fi

echo "=== Dosyalari 5.10'e Entegre Etme ==="

# 1. Device Tree Sources
echo "[1/4] Device Tree..."
if [ -d "$DEVICE_DIR/dts/mediatek" ]; then
    mkdir -p "$LINUX_DIR/arch/arm64/boot/dts/mediatek"
    cp -r "$DEVICE_DIR/dts/mediatek"/* "$LINUX_DIR/arch/arm64/boot/dts/mediatek/"
    echo "  DTS entegre edildi"
fi

# 2. Mediatek Drivers
echo "[2/4] Mediatek Drivers..."
if [ -d "$DEVICE_DIR/drivers/misc/mediatek" ]; then
    mkdir -p "$LINUX_DIR/drivers/misc/mediatek"
    cp -r "$DEVICE_DIR/drivers/misc/mediatek"/* "$LINUX_DIR/drivers/misc/mediatek/"
    echo "  MTK drivers entegre edildi"
fi

# 3. Sound / Audio
echo "[3/4] Ses Driver'lari..."
if [ -d "$DEVICE_DIR/sound/soc/mediatek" ]; then
    mkdir -p "$LINUX_DIR/sound/soc/mediatek"
    cp -r "$DEVICE_DIR/sound/soc/mediatek"/* "$LINUX_DIR/sound/soc/mediatek/"
    echo "  Ses drivers entegre edildi"
fi

# 4. Firmware
echo "[4/4] Firmware..."
if [ -d "$DEVICE_DIR/firmware" ]; then
    mkdir -p "$LINUX_DIR/firmware"
    cp -r "$DEVICE_DIR/firmware"/* "$LINUX_DIR/firmware/"
    echo "  Firmware entegre edildi"
fi

# Update Kconfig/Makefile includes for mediatek subdirs
echo ""
echo "=== Makefile/Kconfig Guncelleme ==="

# Ensure drivers/misc/Makefile includes mediatek
if ! grep -q "mediatek" "$LINUX_DIR/drivers/misc/Makefile" 2>/dev/null; then
    echo "obj-y += mediatek/" >> "$LINUX_DIR/drivers/misc/Makefile"
    echo "  drivers/misc/Makefile guncellendi"
fi

# Ensure sound/soc/Makefile includes mediatek
if ! grep -q "mediatek" "$LINUX_DIR/sound/soc/Makefile" 2>/dev/null; then
    echo "obj-y += mediatek/" >> "$LINUX_DIR/sound/soc/Makefile"
    echo "  sound/soc/Makefile guncellendi"
fi

echo ""
echo "=== Entegrasyon Tamamlandi ==="
