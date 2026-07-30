#!/bin/bash
set -e

echo "🔨 PortGuard Release Derlemesi Başlatılıyor..."

BUILD_DIR=".build/release"
APP_NAME="PortGuard.app"
DIST_DIR="dist"

swift build -c release

echo "📦 .app Paketi Oluşturuluyor..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/$APP_NAME/Contents/MacOS"
mkdir -p "$DIST_DIR/$APP_NAME/Contents/Resources"

cp "$BUILD_DIR/PortGuard" "$DIST_DIR/$APP_NAME/Contents/MacOS/PortGuard"
cp "PortGuard/Resources/Info.plist" "$DIST_DIR/$APP_NAME/Contents/Resources/Info.plist"

echo "APPL????" > "$DIST_DIR/$APP_NAME/Contents/PkgInfo"

cd "$DIST_DIR"
zip -r "PortGuard-macOS.zip" "$APP_NAME"
cd ..

echo "✅ PortGuard Başarıyla Derlendi: $DIST_DIR/PortGuard-macOS.zip ve $DIST_DIR/$APP_NAME"
