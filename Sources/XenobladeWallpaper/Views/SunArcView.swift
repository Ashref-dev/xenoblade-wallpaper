import SwiftUI
import XenoKit

/// A compact visualization of the sun's daily arc with the current sun plotted by
/// azimuth (horizontal) and elevation (vertical). The sky tint follows the sun, so
/// it reads correctly in both light and dark appearance.
struct SunArcView: View {
    let position: SolarCalculator.Position?

    var body: some View {
        Canvas { context, size in
            let horizonY = size.height * 0.66
            let pad: CGFloat = 14

            let skyRect = CGRect(x: 0, y: 0, width: size.width, height: horizonY)
            context.fill(Path(skyRect), with: .linearGradient(
                Gradient(colors: skyColors),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: horizonY)
            ))

            let groundRect = CGRect(x: 0, y: horizonY, width: size.width, height: size.height - horizonY)
            context.fill(Path(groundRect), with: .color(.black.opacity(0.22)))

            var horizon = Path()
            horizon.move(to: CGPoint(x: 0, y: horizonY))
            horizon.addLine(to: CGPoint(x: size.width, y: horizonY))
            context.stroke(horizon, with: .color(.white.opacity(0.30)), lineWidth: 1)

            var arc = Path()
            let arcWidth = size.width - pad * 2
            let topY = pad
            arc.move(to: CGPoint(x: pad, y: horizonY))
            arc.addQuadCurve(
                to: CGPoint(x: size.width - pad, y: horizonY),
                control: CGPoint(x: size.width / 2, y: topY - (horizonY - topY))
            )
            context.stroke(arc, with: .color(.white.opacity(0.22)),
                           style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            guard let position else { return }

            let azClamped = min(max(position.azimuth, 60), 300)
            let xFraction = (azClamped - 60) / (300 - 60)
            let x = pad + arcWidth * xFraction

            let elevClamped = min(max(position.elevation, -12), 90)
            let elevFraction = (elevClamped + 12) / (90 + 12)
            let y = horizonY - (horizonY - topY) * elevFraction

            let sunColor: Color = position.elevation < -6 ? .indigo
                : position.elevation < 8 ? .orange : .yellow
            let glow = CGRect(x: x - 18, y: y - 18, width: 36, height: 36)
            context.fill(Path(ellipseIn: glow), with: .radialGradient(
                Gradient(colors: [sunColor.opacity(0.6), .clear]),
                center: CGPoint(x: x, y: y), startRadius: 2, endRadius: 18
            ))
            let disc = CGRect(x: x - 6, y: y - 6, width: 12, height: 12)
            context.fill(Path(ellipseIn: disc), with: .color(sunColor))
        }
        .frame(height: 120)
        .clipShape(.rect(cornerRadius: 16))
    }

    private var skyColors: [Color] {
        guard let elevation = position?.elevation else {
            return [.blue.opacity(0.5), .cyan.opacity(0.3)]
        }
        switch elevation {
        case ..<(-6):
            return [Color(red: 0.05, green: 0.06, blue: 0.18), Color(red: 0.10, green: 0.12, blue: 0.28)]
        case ..<2:
            return [Color(red: 0.20, green: 0.18, blue: 0.38), Color(red: 0.85, green: 0.45, blue: 0.30)]
        case ..<12:
            return [Color(red: 0.35, green: 0.55, blue: 0.85), Color(red: 0.95, green: 0.70, blue: 0.40)]
        default:
            return [Color(red: 0.25, green: 0.55, blue: 0.95), Color(red: 0.60, green: 0.80, blue: 0.98)]
        }
    }
}
