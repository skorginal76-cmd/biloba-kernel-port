#!/bin/bash
#===============================================================================
# Script: 05-build.sh
# Aciklama: Kernel derleme scripti
# Kullanim: ./05-build.sh <linux-kaynak-dizini>
#===============================================================================
set -euo pipefail

LINUX_SRC="${1:-}"

if [ -z "$LINUX_SRC" ]; then
    echo "Kullanim: $0 <linux-source>"
    exit 1
fi

cd "$LINUX_SRC"

log() { echo "[$(date +%H:%M:%S)] $1"; }

JOBS=$(nproc --all)
log "Derleme basliyor ($JOBS parallel is)..."

# ccache ayarlari
export CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
export CC="ccache ${CC:-clang}"
export CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"

# Build
make O=out ARCH=arm64 \
    CC="$CC" \
    CROSS_COMPILE="$CROSS_COMPILE" \
    -j$JOBS 2>&1 | tee build.log

log "Build tamamlandi!"

# DTB derle (ayri olarak)
log "DTB'ler derleniyor..."
make O=out ARCH=arm64 \
    CC="$CC" \
    CROSS_COMPILE="$CROSS_COMPILE" \
    dtbs -j$JOBS 2>&1 | tee -a build.log

# Ciktilari goster
log "=== Build Ciktilari ==="
ls -lah out/arch/arm64/boot/Image* 2>/dev/null || true
ls -lah out/arch/arm64/boot/dts/mediatek/*.dtb 2>/dev/null || true
