#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BUILD_ROOT="$SCRIPT_DIR/build"
SWIFT_BUILD="$BUILD_ROOT/swift"
APP_BUNDLE="$BUILD_ROOT/Ещё пять.app"
SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX14.2.sdk"

mkdir -p "$BUILD_ROOT/clang-cache" "$APP_BUNDLE/Contents/MacOS"

SDKROOT="$SDK_PATH" \
CLANG_MODULE_CACHE_PATH="$BUILD_ROOT/clang-cache" \
swift build \
    --disable-sandbox \
    --configuration release \
    --package-path "$SCRIPT_DIR" \
    --scratch-path "$SWIFT_BUILD"

install -m 755 "$SWIFT_BUILD/release/DalsheLiveMac" "$APP_BUNDLE/Contents/MacOS/DalsheLiveMac"
install -m 644 "$SCRIPT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "$APP_BUNDLE"
