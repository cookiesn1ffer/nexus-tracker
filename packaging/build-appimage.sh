#!/bin/bash
set -e

VERSION="1.1.0"
APP_NAME="nexus-tracker"
APP_DIR="${APP_NAME}.AppDir"

echo "==> Building Flutter app..."
cd "$(dirname "$0")/.."
flutter pub get
flutter build linux --release

echo "==> Creating AppDir structure..."
rm -rf "packaging/${APP_DIR}"
mkdir -p "packaging/${APP_DIR}/usr/bin"
mkdir -p "packaging/${APP_DIR}/usr/share/applications"
mkdir -p "packaging/${APP_DIR}/usr/share/icons/hicolor/256x256/apps"
mkdir -p "packaging/${APP_DIR}/usr/share/icons/hicolor/128x128/apps"
mkdir -p "packaging/${APP_DIR}/usr/share/icons/hicolor/64x64/apps"
mkdir -p "packaging/${APP_DIR}/usr/share/icons/hicolor/48x48/apps"
mkdir -p "packaging/${APP_DIR}/usr/share/icons/hicolor/32x32/apps"
mkdir -p "packaging/${APP_DIR}/usr/share/icons/hicolor/16x16/apps"

echo "==> Copying app files..."
cp -r build/linux/x64/release/bundle/* "packaging/${APP_DIR}/usr/bin/"

echo "==> Copying desktop file and icons..."
cp packaging/nexus-tracker.desktop "packaging/${APP_DIR}/usr/share/applications/${APP_NAME}.desktop"
cp packaging/nexus-tracker.desktop "packaging/${APP_DIR}/${APP_NAME}.desktop"
cp packaging/icons/nexus-tracker-256.png "packaging/${APP_DIR}/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
cp packaging/icons/nexus-tracker-256.png "packaging/${APP_DIR}/${APP_NAME}.png"
cp packaging/icons/nexus-tracker-128.png "packaging/${APP_DIR}/usr/share/icons/hicolor/128x128/apps/${APP_NAME}.png"
cp packaging/icons/nexus-tracker-64.png "packaging/${APP_DIR}/usr/share/icons/hicolor/64x64/apps/${APP_NAME}.png"
cp packaging/icons/nexus-tracker-48.png "packaging/${APP_DIR}/usr/share/icons/hicolor/48x48/apps/${APP_NAME}.png"
cp packaging/icons/nexus-tracker-32.png "packaging/${APP_DIR}/usr/share/icons/hicolor/32x32/apps/${APP_NAME}.png"
cp packaging/icons/nexus-tracker-16.png "packaging/${APP_DIR}/usr/share/icons/hicolor/16x16/apps/${APP_NAME}.png"

echo "==> Creating AppRun..."
cat > "packaging/${APP_DIR}/AppRun" << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/bin/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/nexus_tracker" "$@"
EOF
chmod +x "packaging/${APP_DIR}/AppRun"

echo "==> Downloading appimagetool..."
cd packaging
if [ ! -f appimagetool-x86_64.AppImage ]; then
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
fi

echo "==> Building AppImage..."
ARCH=x86_64 ./appimagetool-x86_64.AppImage "${APP_DIR}" "${APP_NAME}-${VERSION}-x86_64.AppImage"

echo "==> Done! AppImage created: packaging/${APP_NAME}-${VERSION}-x86_64.AppImage"
