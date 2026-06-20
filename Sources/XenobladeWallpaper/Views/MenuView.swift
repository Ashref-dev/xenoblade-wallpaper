import SwiftUI
import AppKit
import XenoKit

/// The popover shown from the menu-bar item. Compact and token-driven, with glass
/// reserved for the single current-frame surface.
struct MenuView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(WallpaperEngine.self) private var engine
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: Xeno.Spacing.lg) {
            HStack(spacing: Xeno.Spacing.sm) {
                Image(systemName: "sun.max")
                    .font(.title3)
                    .foregroundStyle(Xeno.Color.accent)
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Xenoblade Wallpaper").font(.subheadline.weight(.semibold))
                    Text(settings.locationName)
                        .font(.caption)
                        .foregroundStyle(Xeno.Color.textSecondary)
                }
                Spacer()
            }

            SunArcView(position: engine.currentPosition)

            HStack(spacing: Xeno.Spacing.md) {
                Thumbnail(url: engine.frameImageURL(engine.currentFrame?.fileNumber ?? 1),
                          cornerRadius: Xeno.Radius.sm)
                    .frame(width: 80, height: 50)
                VStack(alignment: .leading, spacing: 3) {
                    Text(engine.currentFrame?.label ?? "-")
                        .font(.subheadline.weight(.semibold))
                    if let position = engine.currentPosition {
                        Text(String(format: "%.1f deg / %@", position.elevation,
                                    position.isRising ? "rising" : "setting"))
                            .font(.caption)
                            .foregroundStyle(Xeno.Color.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(Xeno.Spacing.sm)
            .background(Color.clear.glassEffect(.regular, in: .rect(cornerRadius: Xeno.Radius.md)))
            .overlay(
                RoundedRectangle(cornerRadius: Xeno.Radius.md)
                    .strokeBorder(Xeno.Color.hairline, lineWidth: 1)
            )

            Toggle("Cycle with the sun", isOn: $settings.isEnabled)
                .toggleStyle(.switch)
                .tint(Xeno.Color.accent)
                .font(.callout)

            Divider().overlay(Xeno.Color.hairline)

            HStack(spacing: Xeno.Spacing.sm) {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                } label: {
                    Label("Open", systemImage: "macwindow")
                }
                .buttonStyle(.xenoSecondary)
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
                .buttonStyle(.xenoSecondary)
            }
        }
        .padding(Xeno.Spacing.xl)
        .frame(width: 332)
    }
}
