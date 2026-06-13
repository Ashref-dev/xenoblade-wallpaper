#!/bin/bash
# Generate the Xenoblade Wallpaper app icon (.icns) and the monochrome menu-bar
# template image from the Monado sword SVG.
#
#  - appicon.svg : Monado sword (cyan energy) on a deep Bionis-night squircle.
#  - monado.svg  : the bare sword silhouette, trimmed + re-padded for the menu bar.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
RES="$DIR/../Resources"
SET="$DIR/AppIcon.iconset"
SRC="$DIR/icon_1024.png"

mkdir -p "$RES"

echo "==> Rendering composed app icon (1024)"
rsvg-convert -w 1024 -h 1024 "$DIR/appicon.svg" -o "$SRC"

echo "==> Building iconset -> icns"
rm -rf "$SET"; mkdir -p "$SET"
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

echo "==> In-app icon (256)"
sips -z 256 256 "$SRC" --out "$RES/AppIcon-256.png" >/dev/null

echo "==> Menu-bar template (trimmed sword silhouette, square, black-on-transparent)"
# Render the bare sword large, trim the surrounding whitespace, re-pad to a square
# with a small margin so it sits balanced in the menu bar, then downscale. The
# silhouette stays solid black on transparent; isTemplate is set in code so macOS
# tints it for light/dark automatically.
rsvg-convert -w 1024 -h 1024 "$DIR/monado.svg" -o /tmp/_monado_raw.png
magick /tmp/_monado_raw.png -trim +repage /tmp/_monado_trim.png
EDGE=$(magick /tmp/_monado_trim.png -format '%[fx:int(max(w,h)*1.18)]' info:)
magick /tmp/_monado_trim.png \
    -background none -gravity center -extent "${EDGE}x${EDGE}" \
    -resize 88x88 \
    "$RES/MonadoTemplate.png"
# Also emit a @2x-style high-res copy for crispness if needed by the bundle.
magick /tmp/_monado_trim.png \
    -background none -gravity center -extent "${EDGE}x${EDGE}" \
    -resize 176x176 \
    "$RES/MonadoTemplate@2x.png"

echo "icns done: $DIR/AppIcon.icns"
echo "template done: $RES/MonadoTemplate.png"
