#!/bin/bash
#===============================================================================
# Script: 02-setup-linux-510.sh
# Aciklama: Linux 5.10.257 stable kernel kaynağını indirip hazırlar
# Kullanim: ./02-setup-linux-510.sh <surum> <cikti-dizini>
#===============================================================================
set -euo pipefail

VERSION="${1:-5.10.257}"
OUTPUT="${2:-}"
LINUX_REPO="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"

if [ -z "$OUTPUT" ]; then
    echo "Kullanim: $0 <surum> <cikti-dizini>"
    exit 1
fi

log() { echo "[$(date +%H:%M:%S)] $1"; }

mkdir -p "$OUTPUT"

# Eğer zaten varsa sil (cache değil, temiz başla)
if [ -d "$OUTPUT/.git" ]; then
    log "Mevcut repo bulundu, temizleniyor..."
    cd "$OUTPUT"
    git reset --hard HEAD
    git clean -fdx
else
    log "Linux $VERSION kaynagi indiriliyor..."
    # Shallow clone ile hızlı indir
    git clone --depth=1 --branch "linux-5.10.y" "$LINUX_REPO" "$OUTPUT"
fi

cd "$OUTPUT"

# Belirli tag'e checkout et (v5.10.257 gibi)
TAG="v${VERSION}"
log "Tag'e checkout ediliyor: $TAG"

if git rev-parse "$TAG" >/dev/null 2>&1; then
    git checkout "$TAG" -b "port-${VERSION}" 2>/dev/null || \
        git checkout "port-${VERSION}"
else
    log "UYARI: $TAG bulunamadi, linux-5.10.y branch en son commit kullanilacak"
    git checkout -b "port-${VERSION}"
fi

log "Kernel surum bilgisi:"
make kernelversion 2>/dev/null || head -5 Makefile

# Varsayılan defconfig'i hazırla (baz alınacak)
log "Varsayilan defconfig hazirlaniyor..."
make ARCH=arm64 defconfig 2>/dev/null || true

log "Linux $VERSION hazir: $OUTPUT"
