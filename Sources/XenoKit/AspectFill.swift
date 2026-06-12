import Foundation
import AppKit

/// Renders a source image to fill an exact target pixel size using aspect-fill
/// (scale-to-cover + center-crop). This guarantees the desktop wallpaper exactly
/// matches the screen, so macOS never letterboxes it with a colored bar on any
/// edge — the image always fills the whole screen, cropping the overflow.
public enum AspectFill {

    /// The destination rectangle (in target coordinates) the source must be drawn
    /// into so it fully COVERS the target, preserving aspect ratio and centering.
    /// The returned rect always satisfies: minX <= 0, minY <= 0,
    /// maxX >= target.width, maxY >= target.height (i.e. no gaps).
    public static func coverRect(source: CGSize, target: CGSize) -> CGRect {
        guard source.width > 0, source.height > 0,
              target.width > 0, target.height > 0 else {
            return CGRect(origin: .zero, size: target)
        }
        let scale = max(target.width / source.width, target.height / source.height)
        let drawWidth = source.width * scale
        let drawHeight = source.height * scale
        let originX = (target.width - drawWidth) / 2.0
        let originY = (target.height - drawHeight) / 2.0
        return CGRect(x: originX, y: originY, width: drawWidth, height: drawHeight)
    }

    /// Render `image` into an opaque bitmap of exactly `pixelSize`, covering it
    /// fully (center-cropped). Returns PNG data, or nil on failure.
    public static func renderPNG(_ image: NSImage, to pixelSize: CGSize) -> Data? {
        let width = Int(pixelSize.width.rounded())
        let height = Int(pixelSize.height.rounded())
        guard width > 0, height > 0 else { return nil }

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        rep.size = NSSize(width: width, height: height)

        guard let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high

        // Opaque black base so any sub-pixel rounding never shows translucency.
        NSColor.black.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()

        let dest = coverRect(source: image.size, target: CGSize(width: width, height: height))
        image.draw(in: dest,
                   from: .zero,
                   operation: .sourceOver,
                   fraction: 1.0,
                   respectFlipped: true,
                   hints: [.interpolation: NSImageInterpolation.high.rawValue])

        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])
    }
}
