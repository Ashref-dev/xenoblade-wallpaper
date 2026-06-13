import Foundation

/// Read-only projection of the 16-frame day cycle for the gallery UI.
///
/// Every entry is derived from `KeyframeMap.keyframes` (the single source of
/// truth) in chronological order, so the gallery can never drift out of sync
/// with the frame-selection logic. Image URLs are resolved through an injected
/// closure (in the app this is `WallpaperEngine.frameImageURL`), which keeps
/// `XenoKit` free of any wallpaper-application side effects and makes the data
/// trivially testable.
public enum GalleryData {

    public struct Frame: Identifiable, Sendable, Equatable {
        public let fileNumber: Int
        public let label: String
        public let elevation: Double
        public let isRising: Bool
        public let imageURL: URL?
        public let isCurrent: Bool

        public var id: Int { fileNumber }

        /// Short human-readable elevation, e.g. "32 deg".
        public var elevationText: String {
            "\(Int(elevation.rounded())) deg"
        }

        public init(fileNumber: Int,
                    label: String,
                    elevation: Double,
                    isRising: Bool,
                    imageURL: URL?,
                    isCurrent: Bool) {
            self.fileNumber = fileNumber
            self.label = label
            self.elevation = elevation
            self.isRising = isRising
            self.imageURL = imageURL
            self.isCurrent = isCurrent
        }
    }

    /// Build the chronological list of gallery frames.
    ///
    /// - Parameters:
    ///   - currentFileNumber: The frame currently applied to the desktop, or
    ///     `nil` if none is known. Exactly one entry is flagged `isCurrent`
    ///     when it matches a real frame; zero entries are flagged when `nil`.
    ///   - imageURL: Resolver for a frame's source image URL.
    public static func frames(currentFileNumber: Int?,
                              imageURL: (Int) -> URL?) -> [Frame] {
        KeyframeMap.keyframes.map { keyframe in
            Frame(
                fileNumber: keyframe.fileNumber,
                label: keyframe.label,
                elevation: keyframe.elevation,
                isRising: keyframe.isRising,
                imageURL: imageURL(keyframe.fileNumber),
                isCurrent: currentFileNumber == keyframe.fileNumber
            )
        }
    }
}
