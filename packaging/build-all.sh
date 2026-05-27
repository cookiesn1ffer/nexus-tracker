#!/bin/bash
set -e

echo "========================================="
echo "  Nexus Tracker - Build All Packages"
echo "========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Building AppImage..."
bash "${SCRIPT_DIR}/build-appimage.sh"
echo ""

echo "==> Building .deb package..."
bash "${SCRIPT_DIR}/build-deb.sh"
echo ""

echo "==> Building Flatpak..."
if command -v flatpak-builder &> /dev/null; then
    bash "${SCRIPT_DIR}/build-flatpak.sh"
else
    echo "    Skipping Flatpak (flatpak-builder not installed)"
    echo "    Install with: sudo apt install flatpak-builder"
fi
echo ""

echo "========================================="
echo "  Build Complete!"
echo "========================================="
echo ""
echo "Packages created:"
ls -lh "${SCRIPT_DIR}"/*.AppImage 2>/dev/null || echo "  - AppImage: not built"
ls -lh "${SCRIPT_DIR}"/*.deb 2>/dev/null || echo "  - .deb: not built"
ls -lh "${SCRIPT_DIR}"/*.flatpak 2>/dev/null || echo "  - Flatpak: not built"
echo ""
