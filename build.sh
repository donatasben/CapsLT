#!/bin/sh
# Builds build/CapsLT.app (Apple Silicon + Intel) and build/CapsLT.zip for sharing.
set -e
cd "$(dirname "$0")"
APP=build/CapsLT.app
rm -rf build && mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/"
for arch in arm64 x86_64; do
  swiftc -O -parse-as-library -target $arch-apple-macos13 main.swift -o build/CapsLT-$arch
done
lipo -create build/CapsLT-arm64 build/CapsLT-x86_64 -output "$APP/Contents/MacOS/CapsLT"
rm build/CapsLT-*
codesign --force --sign - "$APP"
ditto -c -k --keepParent "$APP" build/CapsLT.zip
echo "Built $APP"
