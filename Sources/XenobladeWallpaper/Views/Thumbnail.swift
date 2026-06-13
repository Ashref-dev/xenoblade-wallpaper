import SwiftUI
import AppKit
import XenoKit

@MainActor
final class ImageCache {
    static let shared = ImageCache()
    private var cache: [String: NSImage] = [:]

    func image(at url: URL?) -> NSImage? {
        guard let url else { return nil }
        if let cached = cache[url.path] { return cached }
        guard let image = NSImage(contentsOf: url) else { return nil }
        cache[url.path] = image
        return image
    }
}

/// A frame thumbnail rendered aspect-fill (cover, no distortion) with a refined
/// hairline border, matching the design tokens.
struct Thumbnail: View {
    let url: URL?
    var cornerRadius: CGFloat = Xeno.Radius.md

    var body: some View {
        Group {
            if let image = ImageCache.shared.image(at: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Rectangle().fill(Xeno.Color.well)
                    Image(systemName: "photo")
                        .foregroundStyle(Xeno.Color.textTertiary)
                }
            }
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Xeno.Color.hairline, lineWidth: 1)
        )
    }
}
