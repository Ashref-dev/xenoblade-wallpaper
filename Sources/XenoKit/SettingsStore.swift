import Foundation
import Observation

public struct LocationPreset: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let name: String
    public let latitude: Double
    public let longitude: Double

    public init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }

    public static let tunis = LocationPreset(name: "Tunis, Tunisia", latitude: 36.8065, longitude: 10.1815)

    public static let presets: [LocationPreset] = [
        .tunis,
        LocationPreset(name: "London, UK", latitude: 51.5074, longitude: -0.1278),
        LocationPreset(name: "New York, USA", latitude: 40.7128, longitude: -74.0060),
        LocationPreset(name: "Tokyo, Japan", latitude: 35.6762, longitude: 139.6503),
        LocationPreset(name: "Sydney, Australia", latitude: -33.8688, longitude: 151.2093),
        LocationPreset(name: "Reykjavik, Iceland", latitude: 64.1466, longitude: -21.9426)
    ]
}

/// Observable, `UserDefaults`-backed settings. Survives relaunch.
@Observable
@MainActor
public final class SettingsStore {

    public static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let locationName = "locationName"
        static let updateIntervalMinutes = "updateIntervalMinutes"
        static let isEnabled = "isEnabled"
        static let showInDock = "showInDock"
        static let showMenuBarIcon = "showMenuBarIcon"
    }

    public var latitude: Double { didSet { defaults.set(latitude, forKey: Key.latitude) } }
    public var longitude: Double { didSet { defaults.set(longitude, forKey: Key.longitude) } }
    public var locationName: String { didSet { defaults.set(locationName, forKey: Key.locationName) } }
    public var updateIntervalMinutes: Int { didSet { defaults.set(updateIntervalMinutes, forKey: Key.updateIntervalMinutes) } }
    public var isEnabled: Bool { didSet { defaults.set(isEnabled, forKey: Key.isEnabled) } }
    public var showInDock: Bool { didSet { defaults.set(showInDock, forKey: Key.showInDock) } }
    public var showMenuBarIcon: Bool { didSet { defaults.set(showMenuBarIcon, forKey: Key.showMenuBarIcon) } }

    private init() {
        defaults.register(defaults: [
            Key.latitude: LocationPreset.tunis.latitude,
            Key.longitude: LocationPreset.tunis.longitude,
            Key.locationName: LocationPreset.tunis.name,
            Key.updateIntervalMinutes: 5,
            Key.isEnabled: true,
            Key.showInDock: false,
            Key.showMenuBarIcon: true
        ])
        latitude = defaults.double(forKey: Key.latitude)
        longitude = defaults.double(forKey: Key.longitude)
        locationName = defaults.string(forKey: Key.locationName) ?? LocationPreset.tunis.name
        updateIntervalMinutes = max(1, defaults.integer(forKey: Key.updateIntervalMinutes))
        isEnabled = defaults.bool(forKey: Key.isEnabled)
        showInDock = defaults.bool(forKey: Key.showInDock)
        showMenuBarIcon = defaults.bool(forKey: Key.showMenuBarIcon)
    }

    public func apply(preset: LocationPreset) {
        latitude = preset.latitude
        longitude = preset.longitude
        locationName = preset.name
    }
}
