#!/bin/bash
#===============================================================================
# Script: 04-apply-patches.sh
# Aciklama: Linux 5.10.257 ile Mediatek/Biloba driver'lari arasindaki
#           bilinen API uyumsuzluklarini otomatik duzeltir.
# Kullanim: ./04-apply-patches.sh <linux-kaynak-dizini> <patches-dizini>
#===============================================================================
set -euo pipefail

LINUX_SRC="${1:-}"
PATCHES_DIR="${2:-}"

if [ -z "$LINUX_SRC" ]; then
    echo "Kullanim: $0 <linux-source> [patches-dir]"
    exit 1
fi

log() { echo "[$(date +%H:%M:%S)] $1"; }
cd "$LINUX_SRC"

log "=========================================="
log "5.10 Uyumluluk Patch'leri Uygulaniyor"
log "=========================================="

# 5.10 kernel sürümünü kontrol et
KERNEL_VER=$(make kernelversion 2>/dev/null || echo "unknown")
log "Hedef kernel surumu: $KERNEL_VER"

#===============================================================================
# GENEL API FIX'LER (5.10 ile bilinen uyumsuzluklar)
#===============================================================================

log "[1/10] access_ok() API fix (2 arg -> 1 arg)..."
find drivers -type f -name "*.c" -exec sed -i \
    's/access_ok(VERIFY_READ, \([^,]*\),/access_ok(\1,/' {} + 2>/dev/null || true
find drivers -type f -name "*.c" -exec sed -i \
    's/access_ok(VERIFY_WRITE, \([^,]*\),/access_ok(\1,/' {} + 2>/dev/null || true

log "[2/10] dma_zalloc_coherent -> dma_alloc_coherent..."
find drivers -type f -name "*.c" -exec sed -i \
    's/dma_zalloc_coherent(/dma_alloc_coherent(/g' {} + 2>/dev/null || true

log "[3/10] devm_ioremap_nocache -> devm_ioremap..."
find drivers -type f -name "*.c" -exec sed -i \
    's/devm_ioremap_nocache(/devm_ioremap(/g' {} + 2>/dev/null || true
find drivers -type f -name "*.c" -exec sed -i \
    's/ioremap_nocache(/ioremap(/g' {} + 2>/dev/null || true

log "[4/10] IRQF_DISABLED kaldirildi (5.10)..."
find drivers -type f -name "*.c" -exec sed -i \
    's/| IRQF_DISABLED//g' {} + 2>/dev/null || true
find drivers -type f -name "*.c" -exec sed -i \
    's/IRQF_DISABLED | //g' {} + 2>/dev/null || true

log "[5/10] strlcpy -> strscpy (5.10 onerisi)..."
find drivers -type f -name "*.c" -exec sed -i \
    's/\bstrlcpy(/strscpy(/g' {} + 2>/dev/null || true

log "[6/10] clk_enable/disable -> prepare/unprepare..."
find drivers -type f -name "*.c" -exec sed -i \
    's/\bclk_enable(/clk_prepare_enable(/g' {} + 2>/dev/null || true
find drivers -type f -name "*.c" -exec sed -i \
    's/\bclk_disable(/clk_disable_unprepare(/g' {} + 2>/dev/null || true

log "[7/10] PTR_RET -> PTR_ERR_OR_ZERO..."
find drivers -type f -name "*.c" -exec sed -i \
    's/PTR_RET(/PTR_ERR_OR_ZERO(/g' {} + 2>/dev/null || true

log "[8/10] timespec -> timespec64..."
find drivers -type f -name "*.c" -exec sed -i \
    's/\bstruct timespec\b/struct timespec64/g' {} + 2>/dev/null || true

log "[9/10] i2c_new_device -> i2c_new_client_device (5.10)..."
find drivers -type f -name "*.c" -exec sed -i \
    's/\bi2c_new_device(/i2c_new_client_device(/g' {} + 2>/dev/null || true

log "[10/10] vm_fault_t return type (5.10)..."
# Bu daha dikkatli yapilmali, regex ile temel fix
find drivers -type f -name "*.c" -exec sed -i \
    's/static int \(\w*_fault\)(struct vm_area_struct/static vm_fault_t \1(struct vm_area_struct/g' {} + 2>/dev/null || true

#===============================================================================
# MEDIATEK OZEL FIX'LER
#===============================================================================

log "[Bonus] Mediatek ozel fix'ler uygulaniyor..."

# sched_setscheduler_on -> sched_setscheduler (5.10'da API degisikligi)
find drivers -type f -name "*.c" -exec sed -i \
    's/sched_setscheduler_on(/sched_setscheduler(/g' {} + 2>/dev/null || true

# totalram_pages artik fonksiyon (5.10+)
find drivers -type f -name "*.c" -exec sed -i \
    's/totalram_pages\b/totalram_pages()/g' {} + 2>/dev/null || true

# get_unused_fd -> get_unused_fd_flags (5.10)
find drivers -type f -name "*.c" -exec sed -i \
    's/get_unused_fd()/get_unused_fd_flags(0)/g' {} + 2>/dev/null || true

# inode_lock_nested yoksa inode_lock (5.10'da)
find drivers -type f -name "*.c" -exec sed -i \
    's/inode_lock_nested(/inode_lock(/g' {} + 2>/dev/null || true

# 5.10'da proc_create_data -> proc_create_single_data (bazi durumlar)
find drivers -type f -name "*.c" -exec sed -i \
    's/proc_create_data(/proc_create_data(/g' {} + 2>/dev/null || true

# copy_from_user return degeri (5.10'da access_ok degisikligi ile)
# Bu genelde manuel cozum gerektirir

#===============================================================================
# CUSTOM PATCH'LER (patches/ dizininden)
#===============================================================================

if [ -n "$PATCHES_DIR" ] && [ -d "$PATCHES_DIR" ]; then
    log "Ozel patch'ler kontrol ediliyor: $PATCHES_DIR"
    for patch in $(find "$PATCHES_DIR" -name "*.patch" -o -name "*.diff" | sort); do
        log "  Uygulaniyor: $(basename $patch)"
        if patch -p1 --dry-run -i "$patch" >/dev/null 2>&1; then
            patch -p1 -i "$patch"
            log "    -> Basarili"
        else
            log "    -> Uygulanamadi (atlaniyor)"
        fi
    done
else
    log "Ozel patch dizini bulunamadi, atlaniyor"
fi

log "=========================================="
log "Uyumluluk patch'leri tamamlandi"
log "NOT: Derleme hatalari varsa patches/ dizinine"
log "    ilgili .patch dosyasini ekleyip tekrar calistirin"
log "=========================================="
