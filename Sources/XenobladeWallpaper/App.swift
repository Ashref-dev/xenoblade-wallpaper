import SwiftUI
import AppKit
import ServiceManagement
import XenoKit

@main
struct XenobladeWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var settings = SettingsStore.shared

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environment(settings)
                .environment(appDelegate.engine)
        } label: {
            Image(systemName: menuBarSymbol)
        }
        .menuBarExtraStyle(.window)

        Window("Xenoblade Wallpaper", id: "main") {
            MainView()
                .environment(settings)
                .environment(appDelegate.engine)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 720)
    }

    private var menuBarSymbol: String {
        guard let elevation = appDelegate.engine.currentPosition?.elevation else { return "sun.max" }
        switch elevation {
        case ..<(-6): return "moon.stars.fill"
        case ..<6:    return "sun.horizon.fill"
        default:      return "sun.max.fill"
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let engine = WallpaperEngine(settings: SettingsStore.shared)

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyActivationPolicy()
        engine.start()
        observeSettings()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        WindowOpener.shared.open?()
        return true
    }

    private func applyActivationPolicy() {
        NSApp.setActivationPolicy(SettingsStore.shared.showInDock ? .regular : .accessory)
    }

    private func observeSettings() {
        let settings = SettingsStore.shared
        withObservationTracking {
            _ = settings.showInDock
            _ = settings.updateIntervalMinutes
            _ = settings.latitude
            _ = settings.longitude
            _ = settings.isEnabled
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.applyActivationPolicy()
                self.engine.rescheduleTimer()
                self.engine.update(force: true)
                self.observeSettings()
            }
        }
    }
}

/// Bridges SwiftUI's openWindow so the reopen handler can reveal the main window.
@MainActor
final class WindowOpener {
    static let shared = WindowOpener()
    var open: (() -> Void)?
}

/// Launch-at-login via SMAppService (macOS 13+).
@MainActor
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else {
                if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            }
        } catch {
            NSLog("Helios login item toggle failed: \(error.localizedDescription)")
        }
    }
}
