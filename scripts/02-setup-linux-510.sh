#!/bin/bash
# 02-setup-linux-510.sh
# Downloads and prepares Linux 5.10 stable source

set -e

VERSION="$1"
TARGET="$2"

if [ -z "$VERSION" ] || [ -z "$TARGET" ]; then
    echo "Usage: $0 <kernel-version> <target-dir>"
    exit 1
fi

echo "=== Linux $VERSION Stable Indirme ==="

# Clean target
rm -rf "$TARGET"
mkdir -p "$TARGET"

# Download from kernel.org
TARBALL="linux-${VERSION}.tar.xz"
URL="https://cdn.kernel.org/pub/linux/kernel/v5.x/${TARBALL}"

echo "Indiriliyor: $URL"
if ! wget -q --show-progress "$URL" -O "/tmp/${TARBALL}"; then
    echo "HATA: $VERSION indirilemedi"
    echo "Alternatif: git clone ile indiriliyor..."

    # Fallback to git
    git clone --depth=1 --branch "v${VERSION}"         https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git         "$TARGET"
else
    echo "Cikariliyor..."
    tar -xf "/tmp/${TARBALL}" -C "$(dirname "$TARGET")"
    mv "$(dirname "$TARGET")/linux-${VERSION}" "$TARGET"
    rm -f "/tmp/${TARBALL}"
fi

echo "=== Linux $VERSION Hazir ==="
echo "Dizin: $TARGET"
ls -la "$TARGET"
