import SwiftUI
import XenoKit

/// A compact visualization of the sun's daily arc with the current sun plotted by
/// azimuth (horizontal) and elevation (vertical). The sky tint follows the sun so
/// it reads as an actual sky; the sun marker is tinted with the design tokens
/// (warm accent by day, cool Monado cyan at night) and the panel carries a
/// refined token border and corner radius.
struct SunArcView: View {
    let position: SolarCalculator.Position?

    var body: some View {
        Canvas { context, size in
            let horizonY = size.height * 0.66
            let pad: CGFloat = 16

            let skyRect = CGRect(x: 0, y: 0, width: size.width, height: horizonY)
            context.fill(Path(skyRect), with: .linearGradient(
                Gradient(colors: skyColors),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: horizonY)
            ))

            let groundRect = CGRect(x: 0, y: horizonY, width: size.width, height: size.height - horizonY)
            context.fill(Path(groundRect), with: .color(.black.opacity(0.20)))

            // Strokes sit on the sky gradient, so a soft white reads in both appearances.
            let onSky = Color.white.opacity(0.28)

            var horizon = Path()
            horizon.move(to: CGPoint(x: 0, y: horizonY))
            horizon.addLine(to: CGPoint(x: size.width, y: horizonY))
            context.stroke(horizon, with: .color(onSky), lineWidth: 1)

            var arc = Path()
            let arcWidth = size.width - pad * 2
            let topY = pad
            arc.move(to: CGPoint(x: pad, y: horizonY))
            arc.addQuadCurve(
                to: CGPoint(x: size.width - pad, y: horizonY),
                control: CGPoint(x: size.width / 2, y: topY - (horizonY - topY))
            )
            context.stroke(arc, with: .color(Color.white.opacity(0.20)),
                           style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            guard let position else { return }

            let azClamped = min(max(position.azimuth, 60), 300)
            let xFraction = (azClamped - 60) / (300 - 60)
            let x = pad + arcWidth * xFraction

            let elevClamped = min(max(position.elevation, -12), 90)
            let elevFraction = (elevClamped + 12) / (90 + 12)
            let y = horizonY - (horizonY - topY) * elevFraction

            let sunColor: Color = position.elevation < -6
                ? Xeno.Color.monado
                : Xeno.Color.accent
            let glow = CGRect(x: x - 18, y: y - 18, width: 36, height: 36)
            context.fill(Path(ellipseIn: glow), with: .radialGradient(
                Gradient(colors: [sunColor.opacity(0.55), .clear]),
                center: CGPoint(x: x, y: y), startRadius: 2, endRadius: 18
            ))
            let disc = CGRect(x: x - 6, y: y - 6, width: 12, height: 12)
            context.fill(Path(ellipseIn: disc), with: .color(sunColor))
            context.stroke(Path(ellipseIn: disc), with: .color(.white.opacity(0.55)), lineWidth: 1)
        }
        .frame(height: 116)
        .clipShape(.rect(cornerRadius: Xeno.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Xeno.Radius.md)
                .strokeBorder(Xeno.Color.hairline, lineWidth: 1)
        )
    }

    private var skyColors: [Color] {
        guard let elevation = position?.elevation else {
            return [Color(red: 0.30, green: 0.50, blue: 0.78), Color(red: 0.55, green: 0.72, blue: 0.90)]
        }
        switch elevation {
        case ..<(-6):
            return [Color(red: 0.07, green: 0.08, blue: 0.18), Color(red: 0.14, green: 0.16, blue: 0.30)]
        case ..<2:
            return [Color(red: 0.22, green: 0.20, blue: 0.36), Color(red: 0.74, green: 0.46, blue: 0.34)]
        case ..<12:
            return [Color(red: 0.34, green: 0.52, blue: 0.78), Color(red: 0.84, green: 0.66, blue: 0.44)]
        default:
            return [Color(red: 0.26, green: 0.52, blue: 0.84), Color(red: 0.56, green: 0.74, blue: 0.92)]
        }
    }
}
