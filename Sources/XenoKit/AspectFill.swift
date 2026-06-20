import Foundation
import AppKit
import CoreGraphics

/// Renders a source image to fill an exact target pixel size using aspect-fill
/// (scale-to-cover + center-crop), first trimming any baked-in near-black
/// letterbox bands from the source art. This guarantees the desktop wallpaper
/// exactly matches the screen with no colored or black bar on any edge.
public enum AspectFill {

    /// The destination rectangle (in target coordinates) the source must be drawn
    /// into so it fully COVERS the target, preserving aspect ratio and centering.
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
        var proposed = CGRect(x: 0, y: 0, width: pixelSize.width, height: pixelSize.height)
        guard let cgImage = image.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
            return nil
        }
        return renderPNG(cgImage, to: pixelSize)
    }

    /// Render a `CGImage` to exactly `pixelSize`, trimming near-black borders then
    /// covering the target.
    public static func renderPNG(_ cgImage: CGImage, to pixelSize: CGSize) -> Data? {
        let width = Int(pixelSize.width.rounded())
        let height = Int(pixelSize.height.rounded())
        guard width > 0, height > 0 else { return nil }

        let content = trimmedBlackBorders(cgImage)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let dest = coverRect(source: CGSize(width: content.width, height: content.height),
                             target: CGSize(width: width, height: height))
        context.draw(content, in: dest)

        guard let output = context.makeImage() else { return nil }
        return NSBitmapImageRep(cgImage: output).representation(using: .png, properties: [:])
    }

    /// Crop contiguous near-black rows/columns from each edge of `cgImage` (the
    /// letterbox/pillarbox bars baked into the source art). The trim per edge is
    /// capped by `maxFraction` so a genuinely dark frame is never over-cropped.
    static func trimmedBlackBorders(_ cgImage: CGImage,
                                    threshold: Int = 12,
                                    maxFraction: CGFloat = 0.2) -> CGImage {
        let w = cgImage.width
        let h = cgImage.height
        guard w > 1, h > 1 else { return cgImage }

        let bytesPerPixel = 4
        let bytesPerRow = w * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // Let the context own its backing store so the pointer stays valid for the
        // whole function (a buffer captured via withUnsafeMutableBytes would dangle).
        guard let context = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return cgImage }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))

        guard let dataPointer = context.data else { return cgImage }
        let buffer = dataPointer.bindMemory(to: UInt8.self, capacity: bytesPerRow * h)
        // Buffer row 0 corresponds to the image's TOP scanline, matching the
        // top-left origin that cgImage.cropping expects (verified empirically).

        func rowIsBlack(_ y: Int) -> Bool {
            let base = y * bytesPerRow
            var x = 0
            while x < w {
                let p = base + x * bytesPerPixel
                if Int(buffer[p]) > threshold || Int(buffer[p + 1]) > threshold || Int(buffer[p + 2]) > threshold {
                    return false
                }
                x += 1
            }
            return true
        }
        func columnIsBlack(_ x: Int, _ yLo: Int, _ yHi: Int) -> Bool {
            let xb = x * bytesPerPixel
            var y = yLo
            while y < yHi {
                let p = y * bytesPerRow + xb
                if Int(buffer[p]) > threshold || Int(buffer[p + 1]) > threshold || Int(buffer[p + 2]) > threshold {
                    return false
                }
                y += 1
            }
            return true
        }

        let maxTrimY = Int(CGFloat(h) * maxFraction)
        let maxTrimX = Int(CGFloat(w) * maxFraction)

        var topBlack = 0
        while topBlack < maxTrimY && rowIsBlack(topBlack) { topBlack += 1 }
        var bottomBlack = 0
        while bottomBlack < maxTrimY && rowIsBlack(h - 1 - bottomBlack) { bottomBlack += 1 }
        let yLo = topBlack
        let yHi = h - bottomBlack
        guard yHi - yLo > h / 4 else { return cgImage }

        var left = 0
        while left < maxTrimX && columnIsBlack(left, yLo, yHi) { left += 1 }
        var right = 0
        while right < maxTrimX && columnIsBlack(w - 1 - right, yLo, yHi) { right += 1 }
        let xLo = left
        let xHi = w - right
        guard xHi - xLo > w / 4 else { return cgImage }

        if topBlack == 0 && bottomBlack == 0 && left == 0 && right == 0 { return cgImage }

        let cropRect = CGRect(x: xLo, y: yLo, width: xHi - xLo, height: yHi - yLo)
        return cgImage.cropping(to: cropRect) ?? cgImage
    }
}
