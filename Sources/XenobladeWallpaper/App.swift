import SwiftUI
import AppKit
import ServiceManagement
import XenoKit

@main
struct XenobladeWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var settings = SettingsStore.shared

    var body: some Scene {
        @Bindable var settings = settings

        MenuBarExtra(isInserted: $settings.showMenuBarIcon) {
            MenuView()
                .environment(settings)
                .environment(appDelegate.engine)
        } label: {
            if let image = monadoTemplateImage {
                Image(nsImage: image)
            } else {
                Image(systemName: menuBarSymbol)
            }
        }
        .menuBarExtraStyle(.window)
    }

    /// The Monado glyph used as a template (monochrome, tinted by the menu bar).
    /// Falls back to an SF Symbol if the bundled asset is missing.
    private var monadoTemplateImage: NSImage? {
        guard let url = Bundle.main.url(forResource: "MonadoTemplate", withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
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
    private var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        WindowOpener.shared.open = { [weak self] in self?.revealMainWindow() }
        applyActivationPolicy()
        engine.start()
        observeSettings()
        revealMainWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        revealMainWindow()
        return true
    }

    /// Force the main window to appear and come to the front, even when the app
    /// runs as a hidden agent (no menu-bar icon and no Dock icon). The window is
    /// AppKit-managed so it can be shown without a SwiftUI Window scene, which an
    /// LSUIElement app never auto-opens. orderFrontRegardless is required because
    /// an accessory app cannot always make a window key on its own.
    func revealMainWindow() {
        let window = mainWindow ?? makeMainWindow()
        mainWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func makeMainWindow() -> NSWindow {
        let hosting = NSHostingController(
            rootView: MainView()
                .environment(SettingsStore.shared)
                .environment(engine)
        )
        let window = NSWindow(contentViewController: hosting)
        window.title = "Xenoblade Wallpaper"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.identifier = NSUserInterfaceItemIdentifier("main")
        window.setContentSize(NSSize(width: 600, height: 760))
        window.contentMinSize = NSSize(width: 460, height: 560)
        window.center()
        return window
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
