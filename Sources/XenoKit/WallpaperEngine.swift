import AppKit
import Observation

/// Resolves the current sun position to a Xenoblade frame and applies it to every
/// screen as a perfectly screen-filling wallpaper.
///
/// Each frame is pre-rendered to the exact pixel size of each screen using
/// `AspectFill` (cover + center-crop), so the wallpaper always fills the display
/// with no colored letterbox bar on any edge, regardless of image aspect ratio.
@Observable
@MainActor
public final class WallpaperEngine {

    private let settings: SettingsStore

    public private(set) var currentFrame: KeyframeMap.Keyframe?
    public private(set) var currentPosition: SolarCalculator.Position?
    public private(set) var lastError: String?

    private var timer: Timer?
    private var appliedFileNumber: Int?
    private var observers: [NSObjectProtocol] = []

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    // MARK: - Lifecycle

    public func start() {
        registerObservers()
        scheduleTimer()
        update(force: true)
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }

    public func rescheduleTimer() {
        scheduleTimer()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        let interval = TimeInterval(max(1, settings.updateIntervalMinutes) * 60)
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.update(force: false) }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func registerObservers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        observers.append(workspaceCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reapplyToAllScreens() }
        })
        observers.append(workspaceCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.update(force: true) }
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reapplyToAllScreens() }
        })
    }

    // MARK: - Core update

    public func update(force: Bool) {
        let position = SolarCalculator.position(
            latitude: settings.latitude, longitude: settings.longitude
        )
        let frame = KeyframeMap.keyframe(for: position)
        currentPosition = position
        currentFrame = frame

        guard settings.isEnabled else { return }
        guard force || frame.fileNumber != appliedFileNumber else { return }

        guard sourceImageURL(for: frame.fileNumber) != nil else {
            lastError = "Missing bundled frame image-\(frame.fileNumber).png"
            return
        }
        lastError = nil
        appliedFileNumber = frame.fileNumber
        applyFilling(fileNumber: frame.fileNumber)
    }

    private func reapplyToAllScreens() {
        guard settings.isEnabled, let fileNumber = appliedFileNumber else { return }
        applyFilling(fileNumber: fileNumber)
    }

    // MARK: - Fill-rendering + applying

    /// Render the frame to each screen's exact pixel size (aspect-fill) and set it.
    private func applyFilling(fileNumber: Int) {
        guard let sourceURL = sourceImageURL(for: fileNumber),
              let image = NSImage(contentsOf: sourceURL) else {
            lastError = "Could not load frame image-\(fileNumber).png"
            return
        }

        let workspace = NSWorkspace.shared
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true,
            .fillColor: NSColor.black
        ]

        for screen in NSScreen.screens {
            let scale = screen.backingScaleFactor
            let pixelSize = CGSize(width: screen.frame.width * scale,
                                   height: screen.frame.height * scale)
            guard let renderedURL = renderedURL(fileNumber: fileNumber,
                                                pixelSize: pixelSize,
                                                source: image) else {
                lastError = "Failed to render frame for \(Int(pixelSize.width))x\(Int(pixelSize.height))"
                continue
            }
            do {
                try workspace.setDesktopImageURL(renderedURL, for: screen, options: options)
            } catch {
                lastError = "Failed to set wallpaper: \(error.localizedDescription)"
            }
        }
    }

    /// Return a cached screen-sized aspect-fill render, creating it if absent.
    private func renderedURL(fileNumber: Int, pixelSize: CGSize, source: NSImage) -> URL? {
        let width = Int(pixelSize.width.rounded())
        let height = Int(pixelSize.height.rounded())
        let dir = Self.renderCacheDirectory()
        let url = dir.appendingPathComponent("image-\(fileNumber)-\(width)x\(height).png")
        if FileManager.default.fileExists(atPath: url.path) { return url }

        guard let data = AspectFill.renderPNG(source, to: CGSize(width: width, height: height)) else {
            return nil
        }
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            lastError = "Failed to cache render: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Resource resolution

    public func frameImageURL(_ number: Int) -> URL? {
        sourceImageURL(for: number)
    }

    /// Bundled frame (production) with a dev fallback to the original Pictures set.
    private func sourceImageURL(for number: Int) -> URL? {
        let name = "image-\(number).png"
        if let resources = Bundle.main.resourceURL {
            let bundled = resources.appendingPathComponent("wallpapers/\(name)")
            if FileManager.default.fileExists(atPath: bundled.path) { return bundled }
        }
        let devFallback = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Pictures/xeno-imgs/xeno-images/\(name)")
        return FileManager.default.fileExists(atPath: devFallback.path) ? devFallback : nil
    }

    private static func renderCacheDirectory() -> URL {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )) ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("XenobladeWallpaper/rendered", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Clear cached renders (e.g. after a resolution change). Public for the UI.
    public func clearRenderCache() {
        let dir = Self.renderCacheDirectory()
        try? FileManager.default.removeItem(at: dir)
        appliedFileNumber = nil
    }
}
