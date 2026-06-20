import SwiftUI
import AppKit

/// Centralized, light/dark-adaptive design system for the whole app.
///
/// The palette is deliberately calm: deep slate/ink neutrals carried by the
/// system semantic colors, ONE restrained warm accent (a muted amber/gold) used
/// only for emphasis, and a cool Monado-cyan reserved for the "current frame"
/// highlight. Every view consumes these tokens instead of hardcoding colors,
/// spacing, or radii, so the UI stays consistent and reads correctly in both
/// appearances.
public enum Xeno {

    // MARK: - Color

    public enum Color {
        /// Restrained warm accent (muted amber/gold). Replaces the old bright orange.
        public static let accent = adaptive(
            light: NSColor(srgbRed: 0.78, green: 0.52, blue: 0.16, alpha: 1.0),
            dark:  NSColor(srgbRed: 0.89, green: 0.67, blue: 0.31, alpha: 1.0)
        )

        /// Low-emphasis accent wash for soft fills and selected backgrounds.
        public static let accentSoft = adaptive(
            light: NSColor(srgbRed: 0.78, green: 0.52, blue: 0.16, alpha: 0.12),
            dark:  NSColor(srgbRed: 0.89, green: 0.67, blue: 0.31, alpha: 0.16)
        )

        /// Cool secondary highlight (Monado cyan) for the current-frame emphasis.
        public static let monado = adaptive(
            light: NSColor(srgbRed: 0.16, green: 0.49, blue: 0.58, alpha: 1.0),
            dark:  NSColor(srgbRed: 0.42, green: 0.79, blue: 0.88, alpha: 1.0)
        )

        /// App background. Tracks the window background for native depth.
        public static let background = SwiftUI.Color(nsColor: .windowBackgroundColor)

        /// Card / panel surface, slightly elevated from the background.
        public static let surface = adaptive(
            light: NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            dark:  NSColor(srgbRed: 0.15, green: 0.16, blue: 0.18, alpha: 1.0)
        )

        /// Inset wells (thumbnails, fields) one step recessed from a surface.
        public static let well = adaptive(
            light: NSColor(srgbRed: 0.95, green: 0.95, blue: 0.96, alpha: 1.0),
            dark:  NSColor(srgbRed: 0.11, green: 0.12, blue: 0.13, alpha: 1.0)
        )

        /// Hairline separators and quiet borders.
        public static let hairline = adaptive(
            light: NSColor(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.10),
            dark:  NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.12)
        )

        /// Primary / secondary / tertiary text rely on system semantics.
        public static let textPrimary = SwiftUI.Color.primary
        public static let textSecondary = SwiftUI.Color.secondary
        public static let textTertiary = SwiftUI.Color(nsColor: .tertiaryLabelColor)

        private static func adaptive(light: NSColor, dark: NSColor) -> SwiftUI.Color {
            SwiftUI.Color(nsColor: NSColor(name: nil) { appearance in
                let match = appearance.bestMatch(from: [.aqua, .darkAqua])
                return match == .darkAqua ? dark : light
            })
        }
    }

    // MARK: - Spacing (4pt grid)

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 22
        public static let xxl: CGFloat = 32
        public static let section: CGFloat = 28
    }

    // MARK: - Layout

    /// Content widths that keep the window calm at large sizes instead of
    /// stretching forms and grids edge to edge.
    public enum Layout {
        public static let readableWidth: CGFloat = 560
        public static let maxContentWidth: CGFloat = 880
        public static let contentInset: CGFloat = 28
    }

    // MARK: - Corner radii

    public enum Radius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 22
    }

    // MARK: - Motion

    public enum Motion {
        public static let press = Animation.spring(response: 0.28, dampingFraction: 0.72)
        public static let hover = Animation.easeOut(duration: 0.16)
    }
}

// MARK: - Reusable button styles (hover + pressed)

/// A tactile button style with tasteful hover and pressed feedback, centralized
/// so every button in the app reacts identically.
public struct XenoButtonStyle: ButtonStyle {
    public enum Kind: Sendable { case primary, secondary }

    private let kind: Kind

    public init(_ kind: Kind) { self.kind = kind }

    public func makeBody(configuration: Configuration) -> some View {
        XenoButtonBody(kind: kind, configuration: configuration)
    }

    private struct XenoButtonBody: View {
        let kind: Kind
        let configuration: Configuration
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.callout.weight(.medium))
                .padding(.horizontal, Xeno.Spacing.md)
                .padding(.vertical, Xeno.Spacing.sm - 1)
                .frame(maxWidth: kind == .primary ? .infinity : nil)
                .background(fill, in: .rect(cornerRadius: Xeno.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Xeno.Radius.sm)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
                .foregroundStyle(foreground)
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                .animation(Xeno.Motion.press, value: configuration.isPressed)
                .animation(Xeno.Motion.hover, value: hovering)
                .contentShape(.rect(cornerRadius: Xeno.Radius.sm))
                .onHover { hovering = $0 }
        }

        private var fill: Color {
            switch kind {
            case .primary:
                return Xeno.Color.accent.opacity(configuration.isPressed ? 0.85 : (hovering ? 1.0 : 0.92))
            case .secondary:
                return hovering ? Xeno.Color.accentSoft : Xeno.Color.surface.opacity(0.0)
            }
        }

        private var borderColor: Color {
            switch kind {
            case .primary: return .clear
            case .secondary: return hovering ? Xeno.Color.accent.opacity(0.5) : Xeno.Color.hairline
            }
        }

        private var foreground: Color {
            switch kind {
            case .primary: return .white
            case .secondary: return hovering ? Xeno.Color.accent : Xeno.Color.textPrimary
            }
        }
    }
}

public extension ButtonStyle where Self == XenoButtonStyle {
    static var xenoPrimary: XenoButtonStyle { XenoButtonStyle(.primary) }
    static var xenoSecondary: XenoButtonStyle { XenoButtonStyle(.secondary) }
}

// MARK: - Card surface modifier (hover + selected highlight)

/// Elevated panel surface. Uses a solid token fill by default and reserves glass
/// for the hero and the current-frame highlight, keeping the layout calm.
public struct XenoCardModifier: ViewModifier {
    private let padding: CGFloat
    private let highlighted: Bool
    private let glass: Bool

    @State private var hovering = false

    public init(padding: CGFloat, highlighted: Bool, glass: Bool) {
        self.padding = padding
        self.highlighted = highlighted
        self.glass = glass
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SurfaceBackground(glass: glass))
            .overlay(
                RoundedRectangle(cornerRadius: Xeno.Radius.lg)
                    .strokeBorder(borderColor, lineWidth: highlighted ? 1.5 : 1)
            )
            .animation(Xeno.Motion.hover, value: hovering)
    }

    private var borderColor: Color {
        if highlighted { return Xeno.Color.monado.opacity(0.85) }
        return hovering ? Xeno.Color.hairline.opacity(1.5) : Xeno.Color.hairline
    }

    private struct SurfaceBackground: View {
        let glass: Bool

        var body: some View {
            if glass {
                Color.clear
                    .glassEffect(.regular, in: .rect(cornerRadius: Xeno.Radius.lg))
            } else {
                RoundedRectangle(cornerRadius: Xeno.Radius.lg)
                    .fill(Xeno.Color.surface)
            }
        }
    }
}

public extension View {
    /// Standard panel. `glass` reserved for hero surfaces; `highlighted` adds the
    /// Monado-cyan emphasis ring used for the current frame.
    func xenoCard(padding: CGFloat = Xeno.Spacing.lg,
                  highlighted: Bool = false,
                  glass: Bool = false) -> some View {
        modifier(XenoCardModifier(padding: padding, highlighted: highlighted, glass: glass))
    }

    /// Subtle hover lift for interactive thumbnails / cards.
    func xenoHoverLift() -> some View {
        modifier(XenoHoverLift())
    }
}

/// Reusable hover lift: a small scale + raised feel for tappable cards.
public struct XenoHoverLift: ViewModifier {
    @State private var hovering = false

    public init() {}

    public func body(content: Content) -> some View {
        content
            .scaleEffect(hovering ? 1.02 : 1.0)
            .animation(Xeno.Motion.hover, value: hovering)
            .onHover { hovering = $0 }
    }
}
