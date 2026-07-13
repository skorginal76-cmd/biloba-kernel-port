#!/bin/bash
# 04-apply-patches.sh
# Applies compatibility patches for 5.10

set -e

LINUX_DIR="$1"
PATCH_DIR="$2"

if [ -z "$LINUX_DIR" ] || [ -z "$PATCH_DIR" ]; then
    echo "Usage: $0 <linux-stable-dir> <patches-dir>"
    exit 1
fi

cd "$LINUX_DIR"

echo "=== Patch'leri Uygulama ==="

if [ ! -d "$PATCH_DIR" ]; then
    echo "Patch dizini bulunamadi: $PATCH_DIR"
    exit 0
fi

PATCH_COUNT=0
for patch_file in "$PATCH_DIR"/*.patch; do
    [ -e "$patch_file" ] || continue

    # Skip script patches (bash patches)
    if head -1 "$patch_file" | grep -q "^#!/bin/bash"; then
        echo "Skipping script patch: $(basename "$patch_file")"
        continue
    fi

    echo "Uygulaniyor: $(basename "$patch_file")"
    if git apply --check "$patch_file" 2>/dev/null; then
        git apply "$patch_file"
        echo "  [OK] git apply"
        PATCH_COUNT=$((PATCH_COUNT + 1))
    elif patch -p1 --dry-run < "$patch_file" 2>/dev/null; then
        patch -p1 < "$patch_file"
        echo "  [OK] patch -p1"
        PATCH_COUNT=$((PATCH_COUNT + 1))
    else
        echo "  [FAIL] Patch uygulanamadi: $(basename "$patch_file")"
    fi
done

echo ""
echo "=== $PATCH_COUNT patch uygulandi ==="
