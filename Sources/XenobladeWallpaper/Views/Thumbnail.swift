import SwiftUI
import AppKit

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

struct Thumbnail: View {
    let url: URL?
    var cornerRadius: CGFloat = 12

    var body: some View {
        Group {
            if let image = ImageCache.shared.image(at: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Rectangle().fill(.quaternary)
                    Image(systemName: "photo").foregroundStyle(.secondary)
                }
            }
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
    }
}
