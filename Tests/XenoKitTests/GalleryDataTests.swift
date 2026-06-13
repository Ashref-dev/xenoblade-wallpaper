import Testing
import Foundation
@testable import XenoKit

// MARK: - GalleryData (the new gallery feature, derived from KeyframeMap)

@Suite struct GalleryDataTests {

    @Test func hasExactlySixteenFrames() {
        let frames = GalleryData.frames(currentFileNumber: nil) { _ in nil }
        #expect(frames.count == 16)
    }

    @Test func orderMatchesKeyframeMapChronology() {
        let frames = GalleryData.frames(currentFileNumber: nil) { _ in nil }
        #expect(frames.map(\.fileNumber) == KeyframeMap.keyframes.map(\.fileNumber))
    }

    @Test func everyFrameMirrorsItsKeyframe() {
        let frames = GalleryData.frames(currentFileNumber: nil) { _ in nil }
        for (frame, keyframe) in zip(frames, KeyframeMap.keyframes) {
            #expect(frame.fileNumber == keyframe.fileNumber)
            #expect(frame.elevation == keyframe.elevation)
            #expect(frame.isRising == keyframe.isRising)
            #expect(frame.label == keyframe.label)
        }
    }

    @Test func exactlyOneIsCurrentWhenFileNumberSupplied() {
        let frames = GalleryData.frames(currentFileNumber: 7) { _ in nil }
        #expect(frames.filter(\.isCurrent).count == 1)
        #expect(frames.first(where: \.isCurrent)?.fileNumber == 7)
    }

    @Test func noneAreCurrentWhenFileNumberIsNil() {
        let frames = GalleryData.frames(currentFileNumber: nil) { _ in nil }
        #expect(frames.allSatisfy { !$0.isCurrent })
        #expect(frames.filter(\.isCurrent).isEmpty)
    }

    @Test func imageURLResolverIsConsultedPerFrame() {
        let frames = GalleryData.frames(currentFileNumber: nil) { number in
            URL(string: "file:///image-\(number).png")
        }
        let firstNumber = KeyframeMap.keyframes[0].fileNumber
        #expect(frames[0].imageURL == URL(string: "file:///image-\(firstNumber).png"))
    }
}
