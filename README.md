# Xenoblade Wallpaper

A native macOS menu-bar app that cycles your desktop wallpaper through 16 Xenoblade Chronicles frames following the real position of the sun over your city.

The wallpaper moves from first light, through sunrise, full day, golden hour, sunset, dusk, and night, matched to the sun's actual elevation at your coordinates. No Location Services are used, so it stays pinned to the city you choose.

## Features

- 16-frame day cycle driven by the sun's real elevation (NOAA solar algorithm, no CoreLocation).
- Gallery view showing every frame and the sun position assigned to it, with the current frame highlighted.
- Exact-pixel aspect-fill rendering per screen, so the wallpaper always fills the display with no letterbox bars on any edge.
- Live sun-arc preview, location presets, and editable latitude/longitude.
- Lightweight menu-bar agent with an option to hide the menu-bar icon while the app keeps running.
- Launch at login, adjustable update interval, light and dark mode.

## Requirements

- macOS 26 or later
- Xcode 26 / Swift 6.3 toolchain (to build)
- A folder of 16 source frames named `image-1.png` ... `image-16.png`

## Build and install

```bash
./build.sh            # release build, bundle, sign, deliver .app + .dmg to ~/Desktop
./build.sh --no-run   # build and deliver without launching
./build.sh --debug    # debug build
```

The script builds the app, bundles the 16 frames and the icon, ad-hoc signs the bundle, and writes both `Xenoblade Wallpaper.app` and `Xenoblade Wallpaper.dmg` to your Desktop. Because the app is ad-hoc signed, the first launch needs a right-click then Open.

To run the tests:

```bash
swift test
```

## How it works

`SolarCalculator` computes the sun's elevation and azimuth for the configured coordinates at the current time. `KeyframeMap` anchors each of the 16 frames to an ideal elevation and a rising or setting phase, then selects the frame whose anchor is closest to the current sun. `AspectFill` renders the chosen frame to each screen's exact pixel size (cover and center-crop) so it fills the display edge to edge, and `WallpaperEngine` applies it across all screens and re-applies on a timer, on wake, and on screen or Space changes.

## Project structure

```
Sources/
  XenoKit/                 Library: solar math, keyframe map, aspect-fill, engine, settings, tokens
  XenobladeWallpaper/      Executable: app entry, menu bar, main window, gallery, views
Tests/XenoKitTests/        Swift Testing unit tests
Icon/                      monado.svg + appicon.svg + make-icon.sh (icon source of truth)
build.sh                   Build, bundle, sign, package .app + .dmg
```

## Disclaimer

This is a personal fan project. Xenoblade Chronicles and the Monado are trademarks of Nintendo and Monolith Soft. The artwork is not included in this repository; you supply your own frames.
