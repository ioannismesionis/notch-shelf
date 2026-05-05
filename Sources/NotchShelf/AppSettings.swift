import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var startPinned: Bool {
        didSet { defaults.set(startPinned, forKey: Keys.startPinned) }
    }

    @Published var collapseOnHoverExit: Bool {
        didSet { defaults.set(collapseOnHoverExit, forKey: Keys.collapseOnHoverExit) }
    }

    @Published var autoShowOnTopHover: Bool {
        didSet { defaults.set(autoShowOnTopHover, forKey: Keys.autoShowOnTopHover) }
    }

    @Published var refreshInterval: Double {
        didSet { defaults.set(refreshInterval, forKey: Keys.refreshInterval) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Keys.startPinned: false,
            Keys.collapseOnHoverExit: true,
            Keys.autoShowOnTopHover: true,
            Keys.refreshInterval: 2.0
        ])

        startPinned = defaults.bool(forKey: Keys.startPinned)
        collapseOnHoverExit = defaults.bool(forKey: Keys.collapseOnHoverExit)
        autoShowOnTopHover = defaults.bool(forKey: Keys.autoShowOnTopHover)
        refreshInterval = defaults.double(forKey: Keys.refreshInterval)
    }
}

private enum Keys {
    static let startPinned = "startPinned"
    static let collapseOnHoverExit = "collapseOnHoverExit"
    static let autoShowOnTopHover = "autoShowOnTopHover"
    static let refreshInterval = "refreshInterval"
}
