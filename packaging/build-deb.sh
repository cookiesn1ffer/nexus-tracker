#!/bin/bash
set -e

VERSION="1.1.0"
PKG_NAME="nexus-tracker"
DEB_DIR="${PKG_NAME}_${VERSION}_amd64"

echo "==> Building Flutter app..."
cd "$(dirname "$0")/.."
flutter pub get
flutter build linux --release

echo "==> Creating .deb structure..."
cd packaging
rm -rf "${DEB_DIR}"
mkdir -p "${DEB_DIR}/DEBIAN"
mkdir -p "${DEB_DIR}/opt/${PKG_NAME}"
mkdir -p "${DEB_DIR}/usr/bin"
mkdir -p "${DEB_DIR}/usr/share/applications"
mkdir -p "${DEB_DIR}/usr/share/icons/hicolor/256x256/apps"
mkdir -p "${DEB_DIR}/usr/share/icons/hicolor/128x128/apps"
mkdir -p "${DEB_DIR}/usr/share/icons/hicolor/64x64/apps"
mkdir -p "${DEB_DIR}/usr/share/icons/hicolor/48x48/apps"

echo "==> Copying app files..."
cp -r ../build/linux/x64/release/bundle/* "${DEB_DIR}/opt/${PKG_NAME}/"

echo "==> Creating symlink..."
ln -s "/opt/${PKG_NAME}/nexus_tracker" "${DEB_DIR}/usr/bin/nexus_tracker"

echo "==> Copying desktop file and icons..."
cp nexus-tracker.desktop "${DEB_DIR}/usr/share/applications/${PKG_NAME}.desktop"
cp icons/nexus-tracker-256.png "${DEB_DIR}/usr/share/icons/hicolor/256x256/apps/${PKG_NAME}.png"
cp icons/nexus-tracker-128.png "${DEB_DIR}/usr/share/icons/hicolor/128x128/apps/${PKG_NAME}.png"
cp icons/nexus-tracker-64.png "${DEB_DIR}/usr/share/icons/hicolor/64x64/apps/${PKG_NAME}.png"
cp icons/nexus-tracker-48.png "${DEB_DIR}/usr/share/icons/hicolor/48x48/apps/${PKG_NAME}.png"

echo "==> Creating control file..."
cat > "${DEB_DIR}/DEBIAN/control" << EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libblkid1, liblzma5
Maintainer: CookieSn1ffer <230327296+cookiesn1ffer@users.noreply.github.com>
Description: Personal Accountability App
 A minimal, offline-first personal accountability tracker built with Flutter.
 Set ground rules, track daily progress, log writeups, and build streaks.
 No login, no cloud, 100% local. Works on every device.
Homepage: https://github.com/cookiesn1ffer/nexus-tracker
EOF

echo "==> Building .deb package..."
if command -v dpkg-deb &> /dev/null; then
    dpkg-deb --build "${DEB_DIR}"
else
    echo "    dpkg-deb not found, building manually..."
    cd "${DEB_DIR}"
    tar czf control.tar.gz -C DEBIAN .
    tar czf data.tar.gz --exclude=DEBIAN .
    echo "2.0" > debian-binary
    ar rcs "../${DEB_DIR}.deb" debian-binary control.tar.gz data.tar.gz
    cd ..
    rm -f "${DEB_DIR}/debian-binary" "${DEB_DIR}/control.tar.gz" "${DEB_DIR}/data.tar.gz"
fi

echo "==> Done! .deb created: packaging/${DEB_DIR}.deb"
