import SwiftUI
import XenoKit

/// A scrollable grid of all 16 day-cycle frames in chronological order, each
/// annotated with its assigned sun elevation and rising/setting phase. The frame
/// currently applied to the desktop is highlighted with a Monado-cyan ring and a
/// subtle glass elevation.
struct GalleryView: View {
    @Environment(WallpaperEngine.self) private var engine

    private let columns = [
        GridItem(.adaptive(minimum: 152, maximum: 220), spacing: Xeno.Spacing.md)
    ]

    private var frames: [GalleryData.Frame] {
        GalleryData.frames(currentFileNumber: engine.currentFrame?.fileNumber) { number in
            engine.frameImageURL(number)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Xeno.Spacing.md) {
            HStack(spacing: Xeno.Spacing.sm) {
                Text("Day Cycle")
                    .font(.headline)
                Text("16 frames")
                    .font(.caption)
                    .foregroundStyle(Xeno.Color.textTertiary)
                Spacer()
            }

            LazyVGrid(columns: columns, spacing: Xeno.Spacing.md) {
                ForEach(frames) { frame in
                    GalleryFrameCard(frame: frame)
                }
            }
        }
    }
}

/// One frame tile: aspect-fill thumbnail, label, elevation, and phase glyph.
private struct GalleryFrameCard: View {
    let frame: GalleryData.Frame

    var body: some View {
        VStack(alignment: .leading, spacing: Xeno.Spacing.sm) {
            ZStack(alignment: .topTrailing) {
                Thumbnail(url: frame.imageURL, cornerRadius: Xeno.Radius.md)
                    .frame(height: 92)
                    .frame(maxWidth: .infinity)
                if frame.isCurrent {
                    Text("Now")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Xeno.Spacing.sm)
                        .padding(.vertical, 3)
                        .background(Xeno.Color.monado, in: .capsule)
                        .padding(Xeno.Spacing.sm)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(frame.label)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: Xeno.Spacing.xs) {
                    Image(systemName: frame.isRising ? "arrow.up" : "arrow.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(frame.isCurrent ? Xeno.Color.monado : Xeno.Color.accent)
                    Text(frame.elevationText)
                        .font(.caption)
                        .foregroundStyle(Xeno.Color.textSecondary)
                    Text(frame.isRising ? "rising" : "setting")
                        .font(.caption2)
                        .foregroundStyle(Xeno.Color.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Xeno.Spacing.sm)
        .background(surface)
        .overlay(
            RoundedRectangle(cornerRadius: Xeno.Radius.lg)
                .strokeBorder(frame.isCurrent ? Xeno.Color.monado.opacity(0.9) : Xeno.Color.hairline,
                              lineWidth: frame.isCurrent ? 1.5 : 1)
        )
        .xenoHoverLift()
    }

    @ViewBuilder private var surface: some View {
        if frame.isCurrent {
            Color.clear.glassEffect(.regular, in: .rect(cornerRadius: Xeno.Radius.lg))
        } else {
            RoundedRectangle(cornerRadius: Xeno.Radius.lg).fill(Xeno.Color.surface)
        }
    }
}
