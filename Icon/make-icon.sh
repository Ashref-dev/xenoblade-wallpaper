#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SVG="$DIR/monado.svg"
SET="$DIR/AppIcon.iconset"
SRC="$DIR/icon_1024.png"

rm -rf "$SET"; mkdir -p "$SET"
rsvg-convert -w 1024 -h 1024 "$SVG" -o "$SRC"

gen() { sips -z "$1" "$1" "$SRC" --out "$2" >/dev/null; }
gen 16  "$SET/icon_16x16.png"
gen 32  "$SET/icon_16x16@2x.png"
gen 32  "$SET/icon_32x32.png"
gen 64  "$SET/icon_32x32@2x.png"
gen 128 "$SET/icon_128x128.png"
gen 256 "$SET/icon_128x128@2x.png"
gen 256 "$SET/icon_256x256.png"
gen 512 "$SET/icon_256x256@2x.png"
gen 512 "$SET/icon_512x512.png"
cp "$SRC" "$SET/icon_512x512@2x.png"

iconutil -c icns "$SET" -o "$DIR/AppIcon.icns"

mkdir -p "$DIR/../Resources"
sips -z 256 256 "$SRC" --out "$DIR/../Resources/AppIcon-256.png" >/dev/null
echo "icns done: $DIR/AppIcon.icns"
