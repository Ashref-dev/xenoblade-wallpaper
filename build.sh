#!/bin/bash
# Build Xenoblade Wallpaper, bundle frames + icon, ad-hoc sign, deliver to Desktop.
# Usage:
#   ./build.sh            release build, bundle, deliver to ~/Desktop, relaunch
#   ./build.sh --no-run   build + bundle + deliver, do not launch
#   ./build.sh --debug    debug build

set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
CONFIG="release"
RUN=1
for arg in "$@"; do
    case "$arg" in
        --debug) CONFIG="debug" ;;
        --no-run) RUN=0 ;;
    esac
done

APP_NAME="XenobladeWallpaper"
DISPLAY_APP="Xenoblade Wallpaper"
SRC_IMAGES="$HOME/Pictures/xeno-imgs/xeno-images"
BUILD_BIN="$ROOT/.build/$CONFIG/$APP_NAME"
APP="$ROOT/$DISPLAY_APP.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"

echo "==> Generating icon"
"$ROOT/Icon/make-icon.sh" >/dev/null

echo "==> Building ($CONFIG)"
swift build -c "$CONFIG"

echo "==> Assembling $DISPLAY_APP.app"
rm -rf "$APP"
mkdir -p "$MACOS" "$RES/wallpapers"
cp "$BUILD_BIN" "$MACOS/$APP_NAME"
cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"
cp "$ROOT/Icon/AppIcon.icns" "$RES/AppIcon.icns"
cp "$ROOT/Resources/AppIcon-256.png" "$RES/AppIcon-256.png"
cp "$ROOT/Resources/MonadoTemplate.png" "$RES/MonadoTemplate.png"
cp "$ROOT/Resources/MonadoTemplate@2x.png" "$RES/MonadoTemplate@2x.png"

echo "==> Bundling 16 frames"
for n in $(seq 1 16); do
    cp "$SRC_IMAGES/image-$n.png" "$RES/wallpapers/image-$n.png"
done

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "==> Delivering to Desktop"
DEST="$HOME/Desktop/$DISPLAY_APP.app"
osascript -e "tell application \"$DISPLAY_APP\" to quit" >/dev/null 2>&1 || true
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
sleep 0.5
rm -rf "$DEST"
cp -R "$APP" "$DEST"
echo "==> Delivered: $DEST"

echo "==> Building DMG"
DMG="$HOME/Desktop/$DISPLAY_APP.dmg"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/$DISPLAY_APP.app"
rm -f "$DMG"
if command -v create-dmg >/dev/null 2>&1; then
    create-dmg \
        --volname "$DISPLAY_APP" \
        --volicon "$ROOT/Icon/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 640 400 \
        --icon-size 128 \
        --icon "$DISPLAY_APP.app" 170 190 \
        --app-drop-link 470 190 \
        --hide-extension "$DISPLAY_APP.app" \
        "$DMG" "$STAGE" >/dev/null 2>&1 || true
fi
# create-dmg can exit non-zero while still producing a valid image; fall back to
# hdiutil only if no DMG was written.
if [ ! -f "$DMG" ]; then
    ln -s /Applications "$STAGE/Applications"
    hdiutil create -volname "$DISPLAY_APP" -srcfolder "$STAGE" \
        -ov -format UDZO "$DMG" >/dev/null
fi
rm -rf "$STAGE"
echo "==> DMG: $DMG"

if [ "$RUN" -eq 1 ]; then
    open "$DEST"
fi
