#!/bin/bash
set -e

VERSION="1.1.0"

echo "==> Building Flutter app..."
cd "$(dirname "$0")/.."
flutter pub get
flutter build linux --release

echo "==> Creating bundle archive..."
cd packaging
rm -rf bundle
cp -r ../build/linux/x64/release/bundle .
tar czf bundle.tar.gz bundle

echo "==> Building Flatpak..."
flatpak-builder --force-clean --repo=repo build-dir com.nexustracker.app.yml
flatpak build-bundle repo nexus-tracker-${VERSION}-x86_64.flatpak com.nexustracker.app

echo "==> Done! Flatpak created: packaging/nexus-tracker-${VERSION}-x86_64.flatpak"
