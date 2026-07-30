#!/bin/bash
set -e

echo "🔨 PortGuard Release Derlemesi Başlatılıyor..."

BUILD_DIR=".build/release"
APP_NAME="PortGuard.app"
DIST_DIR="dist"
DMG_NAME="PortGuard-Installer.dmg"

swift build -c release

echo "📦 .app Paketi Oluşturuluyor..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/$APP_NAME/Contents/MacOS"
mkdir -p "$DIST_DIR/$APP_NAME/Contents/Resources"

cp "$BUILD_DIR/PortGuard" "$DIST_DIR/$APP_NAME/Contents/MacOS/PortGuard"
cp "PortGuard/Resources/Info.plist" "$DIST_DIR/$APP_NAME/Contents/Resources/Info.plist"

echo "APPL????" > "$DIST_DIR/$APP_NAME/Contents/PkgInfo"

cd "$DIST_DIR"
echo "🤐 ZIP Arşivi Oluşturuluyor..."
zip -r "PortGuard-macOS.zip" "$APP_NAME"

echo "💿 .dmg Kurulum Dosyası (Installer Image) Oluşturuluyor..."
STAGING_DIR="dmg_staging"
mkdir -p "$STAGING_DIR"
cp -R "$APP_NAME" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -volname "PortGuard Installer" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"
rm -rf "$STAGING_DIR"

cd ..

echo "✅ PortGuard Başarıyla Derlendi:"
echo "   - $DIST_DIR/$DMG_NAME"
echo "   - $DIST_DIR/PortGuard-macOS.zip"
echo "   - $DIST_DIR/$APP_NAME"
