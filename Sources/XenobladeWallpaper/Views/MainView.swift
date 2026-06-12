import SwiftUI
import AppKit
import XenoKit

/// The main window: branded hero, live sun status, location selection, and options.
/// Uses Liquid Glass surfaces and semantic colors so it reads in light and dark.
struct MainView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(WallpaperEngine.self) private var engine
    @Environment(\.openWindow) private var openWindow

    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            GlassEffectContainer(spacing: 16) {
                VStack(spacing: 16) {
                    hero
                    statusCard
                    locationCard(settings: settings)
                    optionsCard(settings: settings)
                    footer
                }
                .padding(20)
            }
        }
        .frame(minWidth: 480, minHeight: 720)
        .background(.background)
        .onAppear {
            WindowOpener.shared.open = {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Group {
                if let icon = ImageCache.shared.image(at: Bundle.main.url(forResource: "AppIcon-256", withExtension: "png")) {
                    Image(nsImage: icon).resizable()
                } else {
                    Image(systemName: "sun.max.fill").resizable().foregroundStyle(.orange)
                }
            }
            .frame(width: 84, height: 84)
            .clipShape(.rect(cornerRadius: 18))

            Text("Xenoblade Wallpaper")
                .font(.title2.weight(.semibold))
            Text("Your desktop follows the sun over Bionis.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Now", systemImage: "sparkles")
            SunArcView(position: engine.currentPosition)
            HStack(spacing: 14) {
                Thumbnail(url: engine.frameImageURL(engine.currentFrame?.fileNumber ?? 1))
                    .frame(width: 120, height: 72)
                VStack(alignment: .leading, spacing: 3) {
                    Text(engine.currentFrame?.label ?? "—")
                        .font(.headline)
                    if let position = engine.currentPosition {
                        Label(String(format: "%.1f° elevation", position.elevation),
                              systemImage: position.isRising ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(String(format: "Azimuth %.0f°", position.azimuth))
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
            }
        }
        .cardStyle()
    }

    private func locationCard(settings: SettingsStore) -> some View {
        @Bindable var settings = settings
        return VStack(alignment: .leading, spacing: 12) {
            cardTitle("Location", systemImage: "location.fill")
            Text("Computed from these coordinates only — never from Location Services, so it stays accurate to your city.")
                .font(.caption).foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LocationPreset.presets) { preset in
                        Button(preset.name) { settings.apply(preset: preset) }
                            .buttonStyle(.glass)
                            .font(.caption)
                    }
                }
            }

            labeledField("Name") {
                TextField("Location name", text: $settings.locationName)
                    .textFieldStyle(.roundedBorder)
            }
            HStack(spacing: 12) {
                labeledField("Latitude") {
                    TextField("Latitude", value: $settings.latitude,
                              format: .number.precision(.fractionLength(4)))
                        .textFieldStyle(.roundedBorder)
                }
                labeledField("Longitude") {
                    TextField("Longitude", value: $settings.longitude,
                              format: .number.precision(.fractionLength(4)))
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .cardStyle()
    }

    private func optionsCard(settings: SettingsStore) -> some View {
        @Bindable var settings = settings
        return VStack(alignment: .leading, spacing: 12) {
            cardTitle("Options", systemImage: "gearshape.fill")
            Toggle("Cycle wallpaper with the sun", isOn: $settings.isEnabled).tint(.orange)
            Toggle("Launch at login", isOn: $launchAtLogin)
                .tint(.orange)
                .onChange(of: launchAtLogin) { _, newValue in LoginItem.setEnabled(newValue) }
            Toggle("Show in Dock", isOn: $settings.showInDock).tint(.orange)
            Divider().opacity(0.3)
            Stepper(value: $settings.updateIntervalMinutes, in: 1...60) {
                Text("Update every \(settings.updateIntervalMinutes) min")
            }
        }
        .cardStyle()
    }

    private var footer: some View {
        HStack {
            Button {
                engine.update(force: true)
            } label: {
                Label("Apply Now", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.glassProminent)

            Spacer()

            if let error = engine.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.yellow).lineLimit(1)
            } else {
                Text("v\(appVersion)")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }

    private func cardTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage).font(.headline)
    }

    private func labeledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}
