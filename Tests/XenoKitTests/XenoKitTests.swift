import Testing
import Foundation
import AppKit
@testable import XenoKit

// MARK: - AspectFill (the fill-fix: no letterbox bars, ever)

@Suite struct AspectFillTests {

    @Test func coverRectScalesUpToCoverTallerTarget() {
        // Square source into wide target -> scale by the larger ratio (width).
        let rect = AspectFill.coverRect(source: CGSize(width: 100, height: 100),
                                        target: CGSize(width: 300, height: 200))
        #expect(rect.width == 300)
        #expect(rect.height == 300)
        #expect(rect.origin.x == 0)
        #expect(rect.origin.y == -50)
    }

    @Test func coverRectAlwaysCoversTarget() {
        // Whatever the source aspect, the draw rect must leave NO gap on any edge.
        let targets = [CGSize(width: 3024, height: 1964), CGSize(width: 1920, height: 1080)]
        let sources = [CGSize(width: 6756, height: 3824),  // the real Xenoblade frames
                       CGSize(width: 100, height: 400),
                       CGSize(width: 400, height: 100),
                       CGSize(width: 1000, height: 1000)]
        for target in targets {
            for source in sources {
                let r = AspectFill.coverRect(source: source, target: target)
                #expect(r.minX <= 0.0001)
                #expect(r.minY <= 0.0001)
                #expect(r.maxX >= target.width - 0.0001)
                #expect(r.maxY >= target.height - 0.0001)
            }
        }
    }

    @MainActor @Test func renderProducesExactSizeFullyCovered() throws {
        // A solid-red source rendered to a different aspect must yield an image of
        // EXACTLY the target size whose every sampled pixel is red — proving there
        // is no black/blue letterbox bar anywhere.
        let source = Self.solidImage(.red, NSSize(width: 200, height: 200))
        let data = try #require(AspectFill.renderPNG(source, to: CGSize(width: 600, height: 400)))
        let rep = try #require(NSBitmapImageRep(data: data))
        #expect(rep.pixelsWide == 600)
        #expect(rep.pixelsHigh == 400)

        let samples = [(1, 1), (599, 1), (1, 399), (599, 399), (300, 200)]
        for (x, y) in samples {
            let color = try #require(rep.colorAt(x: x, y: y))
            #expect(color.redComponent > 0.9)
            #expect(color.greenComponent < 0.2)
            #expect(color.blueComponent < 0.2)
        }
    }

    @MainActor private static func solidImage(_ color: NSColor, _ size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }
}

// MARK: - SolarCalculator (location accuracy)

@Suite struct SolarCalculatorTests {
    private static func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    @Test func tunisSummerSolarNoonElevation() {
        let p = SolarCalculator.position(date: Self.date("2026-06-21T11:21:00Z"),
                                         latitude: 36.8065, longitude: 10.1815)
        #expect(abs(p.elevation - 76.6) < 1.0)
    }

    @Test func tunisWinterSolarNoonElevation() {
        let p = SolarCalculator.position(date: Self.date("2026-12-21T11:21:00Z"),
                                         latitude: 36.8065, longitude: 10.1815)
        #expect(abs(p.elevation - 29.8) < 1.0)
    }

    @Test func risingBeforeNoonSettingAfter() {
        let morning = SolarCalculator.position(date: Self.date("2026-06-21T06:00:00Z"),
                                               latitude: 36.8065, longitude: 10.1815)
        let evening = SolarCalculator.position(date: Self.date("2026-06-21T16:00:00Z"),
                                               latitude: 36.8065, longitude: 10.1815)
        #expect(morning.isRising == true)
        #expect(evening.isRising == false)
    }
}

// MARK: - KeyframeMap (frame selection)

@Suite struct KeyframeMapTests {
    @Test func nightDeepBelowHorizonPicksNight() {
        let p = SolarCalculator.Position(elevation: -16, azimuth: 0, isRising: false)
        #expect(KeyframeMap.keyframe(for: p).fileNumber == 14)
    }

    @Test func highNoonPicksMidday() {
        let p = SolarCalculator.Position(elevation: 64, azimuth: 180, isRising: true)
        #expect(KeyframeMap.keyframe(for: p).fileNumber == 7)
    }

    @Test func lowSettingPicksSunset() {
        // Matches the verified live behavior: 4 deg, setting -> image-12.
        let p = SolarCalculator.Position(elevation: 4, azimuth: 296, isRising: false)
        #expect(KeyframeMap.keyframe(for: p).fileNumber == 12)
    }
}
