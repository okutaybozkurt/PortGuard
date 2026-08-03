#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "❌ Hata: Yeni sürüm numarası belirtilmedi."
  echo "Kullanım: ./scripts/bump_version.sh <yeni_sürüm>"
  echo "Örnek: ./scripts/bump_version.sh 1.0.3"
  exit 1
fi

NEW_VERSION=$1
PLIST="PortGuard/Resources/Info.plist"

echo "🔄 PortGuard sürümü $NEW_VERSION olarak güncelleniyor..."

# Mevcut build (derleme) numarasını al ve 1 artır
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST")
NEW_BUILD=$((CURRENT_BUILD + 1))

# Info.plist dosyasındaki sürüm stringlerini güncelle
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$PLIST"

echo "✅ Info.plist başarıyla güncellendi (Sürüm: $NEW_VERSION, Build: $NEW_BUILD)"
echo "🚀 Artık Github'a pushlayabilir veya ./scripts/build_app.sh ile derleyebilirsiniz."
