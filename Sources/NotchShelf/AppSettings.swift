import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var startPinned: Bool {
        didSet { defaults.set(startPinned, forKey: Keys.startPinned) }
    }

    @Published var refreshInterval: Double {
        didSet { defaults.set(refreshInterval, forKey: Keys.refreshInterval) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Keys.startPinned: false,
            Keys.refreshInterval: 2.0
        ])

        startPinned = defaults.bool(forKey: Keys.startPinned)
        refreshInterval = defaults.double(forKey: Keys.refreshInterval)
    }
}

private enum Keys {
    static let startPinned = "startPinned"
    static let refreshInterval = "refreshInterval"
}
