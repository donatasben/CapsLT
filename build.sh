#!/bin/sh
# Builds build/CapsLT.app (Apple Silicon + Intel) and build/CapsLT.zip for sharing.
set -e
cd "$(dirname "$0")"
APP=build/CapsLT.app
RES="$APP/Contents/Resources"
rm -rf build && mkdir -p "$APP/Contents/MacOS" "$RES" build/AppIcon.iconset
cp Info.plist "$APP/Contents/"

# App icon (.icns) and menu bar icon (18 pt, @1x + @2x)
for s in 16 32 128 256 512; do
  sips -z $s $s "icons/CapsLT icon.png" --out build/AppIcon.iconset/icon_${s}x${s}.png >/dev/null
  sips -z $((s*2)) $((s*2)) "icons/CapsLT icon.png" --out build/AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns build/AppIcon.iconset -o "$RES/AppIcon.icns"
rm -r build/AppIcon.iconset
sips --resampleHeight 18 "icons/CapsLT menu icon@2x.png" --out "$RES/MenuIcon.png" >/dev/null
sips --resampleHeight 36 "icons/CapsLT menu icon@2x.png" --out "$RES/MenuIcon@2x.png" >/dev/null
for arch in arm64 x86_64; do
  swiftc -O -parse-as-library -target $arch-apple-macos13 main.swift -o build/CapsLT-$arch
done
lipo -create build/CapsLT-arm64 build/CapsLT-x86_64 -output "$APP/Contents/MacOS/CapsLT"
rm build/CapsLT-*
codesign --force --sign - "$APP"
ditto -c -k --keepParent "$APP" build/CapsLT.zip
echo "Built $APP"
