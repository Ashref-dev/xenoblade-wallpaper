import Foundation

/// Maps a sun position to one of the 16 bundled Xenoblade frames.
///
/// Chronological cycle (confirmed with the user):
///   night (14,15) -> first light (16) -> sunrise/slightly brighter (1)
///   -> full bright day (2...10) -> golden hour (11) -> setting (12)
///   -> dusk, red fading (13) -> back to night.
///
/// Each frame is anchored to an ideal sun elevation and a rising/setting phase,
/// mirroring how Apple's native solar wallpapers anchor frames to altitude. At
/// runtime the frame whose anchor is closest to the current sun is selected.
public enum KeyframeMap {

    public struct Keyframe: Sendable, Equatable {
        public let fileNumber: Int
        public let elevation: Double
        public let isRising: Bool
        public let label: String
    }

    private static let phasePenalty: Double = 8.0

    public static let keyframes: [Keyframe] = [
        Keyframe(fileNumber: 16, elevation:  -5, isRising: true,  label: "First Light"),
        Keyframe(fileNumber:  1, elevation:   2, isRising: true,  label: "Sunrise"),
        Keyframe(fileNumber:  2, elevation:  12, isRising: true,  label: "Early Morning"),
        Keyframe(fileNumber:  3, elevation:  22, isRising: true,  label: "Morning"),
        Keyframe(fileNumber:  4, elevation:  32, isRising: true,  label: "Mid Morning"),
        Keyframe(fileNumber:  5, elevation:  44, isRising: true,  label: "Late Morning"),
        Keyframe(fileNumber:  6, elevation:  56, isRising: true,  label: "Approaching Noon"),
        Keyframe(fileNumber:  7, elevation:  64, isRising: true,  label: "Noon"),
        Keyframe(fileNumber:  8, elevation:  54, isRising: false, label: "Early Afternoon"),
        Keyframe(fileNumber:  9, elevation:  40, isRising: false, label: "Afternoon"),
        Keyframe(fileNumber: 10, elevation:  24, isRising: false, label: "Late Afternoon"),
        Keyframe(fileNumber: 11, elevation:   8, isRising: false, label: "Golden Hour"),
        Keyframe(fileNumber: 12, elevation:   1, isRising: false, label: "Sunset"),
        Keyframe(fileNumber: 13, elevation:  -5, isRising: false, label: "Dusk"),
        Keyframe(fileNumber: 15, elevation: -10, isRising: false, label: "Nightfall"),
        Keyframe(fileNumber: 14, elevation: -16, isRising: false, label: "Night")
    ]

    public static func keyframe(for position: SolarCalculator.Position) -> Keyframe {
        keyframes.min { cost($0, position) < cost($1, position) } ?? keyframes[0]
    }

    private static func cost(_ frame: Keyframe, _ position: SolarCalculator.Position) -> Double {
        abs(frame.elevation - position.elevation)
            + ((frame.isRising != position.isRising) ? phasePenalty : 0.0)
    }
}
