import SwiftUI
import AppKit
import XenoKit

/// The popover shown from the menu-bar item.
struct MenuView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(WallpaperEngine.self) private var engine
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sun.max.fill")
                    .font(.title2).foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Xenoblade Wallpaper").font(.headline)
                    Text(settings.locationName).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }

            SunArcView(position: engine.currentPosition)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))

            HStack(spacing: 12) {
                Thumbnail(url: engine.frameImageURL(engine.currentFrame?.fileNumber ?? 1))
                    .frame(width: 84, height: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text(engine.currentFrame?.label ?? "—")
                        .font(.subheadline.weight(.semibold))
                    if let position = engine.currentPosition {
                        Text(String(format: "%.1f° · %@", position.elevation,
                                    position.isRising ? "rising" : "setting"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(10)
            .glassEffect(.regular.tint(.orange.opacity(0.18)), in: .rect(cornerRadius: 14))

            Toggle("Cycle with the sun", isOn: $settings.isEnabled)
                .toggleStyle(.switch).tint(.orange)

            Divider().opacity(0.4)

            HStack {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                } label: {
                    Label("Open", systemImage: "macwindow")
                }
                .buttonStyle(.glass)
                Spacer()
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
                .buttonStyle(.glass)
            }
        }
        .padding(18)
        .frame(width: 320)
    }
}
