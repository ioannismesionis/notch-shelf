import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var startPinned: Bool {
        didSet { defaults.set(startPinned, forKey: Keys.startPinned) }
    }

    @Published var refreshInterval: Double {
        didSet { defaults.set(refreshInterval, forKey: Keys.refreshInterval) }
    }

    @Published var spotifyClientID: String {
        didSet { defaults.set(spotifyClientID, forKey: Keys.spotifyClientID) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Keys.startPinned: false,
            Keys.refreshInterval: 2.0,
            Keys.spotifyClientID: ""
        ])

        startPinned = defaults.bool(forKey: Keys.startPinned)
        refreshInterval = defaults.double(forKey: Keys.refreshInterval)
        spotifyClientID = defaults.string(forKey: Keys.spotifyClientID) ?? ""
    }
}

private enum Keys {
    static let startPinned = "startPinned"
    static let refreshInterval = "refreshInterval"
    static let spotifyClientID = "spotifyClientID"
}
