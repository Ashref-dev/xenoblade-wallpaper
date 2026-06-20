import SwiftUI
import AppKit
import XenoKit

/// The main window: a compact header, a segmented switch between the live "Now"
/// status and the full frame "Gallery", plus location and options. Built on the
/// shared design tokens with glass reserved for the hero and the current frame.
struct MainView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(WallpaperEngine.self) private var engine

    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var section: Section = .now

    private enum Section: String, CaseIterable, Identifiable {
        case now = "Now"
        case gallery = "Gallery"
        var id: String { rawValue }
    }

    var body: some View {
        @Bindable var settings = settings

        VStack(spacing: 0) {
            header
            Divider().overlay(Xeno.Color.hairline)

            ScrollView {
                VStack(spacing: Xeno.Spacing.section) {
                    Picker("Section", selection: $section) {
                        ForEach(Section.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: Xeno.Layout.readableWidth)

                    switch section {
                    case .now:
                        nowContent(settings: settings)
                    case .gallery:
                        GalleryView()
                    }

                    footer
                        .frame(maxWidth: Xeno.Layout.readableWidth)
                }
                .padding(Xeno.Layout.contentInset)
                .frame(maxWidth: Xeno.Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 460, idealWidth: 600, maxWidth: .infinity,
               minHeight: 560, idealHeight: 760, maxHeight: .infinity)
        .background(Xeno.Color.background)
    }

    private func nowContent(settings: SettingsStore) -> some View {
        VStack(spacing: Xeno.Spacing.section) {
            statusCard
            locationSection(settings: settings)
            optionsSection(settings: settings)
        }
        .frame(maxWidth: Xeno.Layout.readableWidth)
    }

    // MARK: - Header (hero)

    private var header: some View {
        HStack(spacing: Xeno.Spacing.md) {
            Group {
                if let icon = ImageCache.shared.image(at: Bundle.main.url(forResource: "AppIcon-256", withExtension: "png")) {
                    Image(nsImage: icon).resizable()
                } else {
                    Image(systemName: "sun.max.fill").resizable().foregroundStyle(Xeno.Color.accent)
                }
            }
            .frame(width: 38, height: 38)
            .clipShape(.rect(cornerRadius: Xeno.Radius.md))

            VStack(alignment: .leading, spacing: 2) {
                Text("Xenoblade Wallpaper")
                    .font(.headline)
                Text("Your desktop follows the sun over Bionis.")
                    .font(.caption)
                    .foregroundStyle(Xeno.Color.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, Xeno.Layout.contentInset)
        .padding(.vertical, Xeno.Spacing.lg)
    }

    // MARK: - Now

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: Xeno.Spacing.lg) {
            cardTitle("Now", systemImage: "sun.max")
            SunArcView(position: engine.currentPosition)
            HStack(spacing: Xeno.Spacing.lg) {
                Thumbnail(url: engine.frameImageURL(engine.currentFrame?.fileNumber ?? 1))
                    .frame(width: 120, height: 74)
                VStack(alignment: .leading, spacing: Xeno.Spacing.xs) {
                    Text(engine.currentFrame?.label ?? "-")
                        .font(.headline)
                    if let position = engine.currentPosition {
                        Label(String(format: "%.1f deg elevation", position.elevation),
                              systemImage: position.isRising ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                            .foregroundStyle(Xeno.Color.textSecondary)
                        Text(String(format: "Azimuth %.0f deg", position.azimuth))
                            .font(.caption2)
                            .foregroundStyle(Xeno.Color.textTertiary)
                    }
                }
                Spacer()
            }
        }
        .xenoCard(padding: Xeno.Spacing.xl, glass: true)
    }

    private func locationSection(settings: SettingsStore) -> some View {
        @Bindable var settings = settings
        return section("Location", systemImage: "location") {
            Text("Computed from these coordinates only - never from Location Services, so it stays accurate to your city.")
                .font(.caption)
                .foregroundStyle(Xeno.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Xeno.Spacing.sm) {
                    ForEach(LocationPreset.presets) { preset in
                        Button(preset.name) { settings.apply(preset: preset) }
                            .buttonStyle(.xenoSecondary)
                    }
                }
                .padding(.bottom, 2)
            }

            labeledField("Name") {
                TextField("Location name", text: $settings.locationName)
                    .textFieldStyle(.roundedBorder)
            }
            HStack(spacing: Xeno.Spacing.md) {
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
    }

    private func optionsSection(settings: SettingsStore) -> some View {
        @Bindable var settings = settings
        return section("Options", systemImage: "gearshape") {
            VStack(alignment: .leading, spacing: Xeno.Spacing.md) {
                Toggle("Cycle wallpaper with the sun", isOn: $settings.isEnabled)
                    .tint(Xeno.Color.accent)
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .tint(Xeno.Color.accent)
                    .onChange(of: launchAtLogin) { _, newValue in LoginItem.setEnabled(newValue) }
                Toggle("Show in Dock", isOn: $settings.showInDock)
                    .tint(Xeno.Color.accent)
                VStack(alignment: .leading, spacing: Xeno.Spacing.xs) {
                    Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)
                        .tint(Xeno.Color.accent)
                    Text("When hidden, the app keeps running. Open it again to show this window.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Stepper(value: $settings.updateIntervalMinutes, in: 1...60) {
                    Text("Update every \(settings.updateIntervalMinutes) min")
                        .font(.callout)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: Xeno.Spacing.md) {
            Button {
                engine.update(force: true)
            } label: {
                Label("Apply Now", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.xenoPrimary)
            .frame(maxWidth: 160)

            Spacer()

            if let error = engine.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Xeno.Color.accent)
                    .lineLimit(1)
            } else {
                Text("v\(appVersion)")
                    .font(.caption2)
                    .foregroundStyle(Xeno.Color.textTertiary)
            }
        }
    }

    private func cardTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Xeno.Color.textPrimary)
    }

    private func section<Content: View>(_ title: String,
                                        systemImage: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Xeno.Spacing.md) {
            cardTitle(title, systemImage: systemImage)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func labeledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Xeno.Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Xeno.Color.textSecondary)
            content()
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
