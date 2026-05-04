import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var showSpotifyWidget: Bool {
        didSet { defaults.set(showSpotifyWidget, forKey: Keys.showSpotifyWidget) }
    }

    @Published var showCalendarWidget: Bool {
        didSet { defaults.set(showCalendarWidget, forKey: Keys.showCalendarWidget) }
    }

    @Published var showInfoTiles: Bool {
        didSet { defaults.set(showInfoTiles, forKey: Keys.showInfoTiles) }
    }

    @Published var showFileShelf: Bool {
        didSet { defaults.set(showFileShelf, forKey: Keys.showFileShelf) }
    }

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

    @Published var calendarLookaheadDays: Int {
        didSet { defaults.set(calendarLookaheadDays, forKey: Keys.calendarLookaheadDays) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Keys.showSpotifyWidget: true,
            Keys.showCalendarWidget: true,
            Keys.showInfoTiles: true,
            Keys.showFileShelf: true,
            Keys.startPinned: false,
            Keys.collapseOnHoverExit: true,
            Keys.autoShowOnTopHover: true,
            Keys.refreshInterval: 2.0,
            Keys.calendarLookaheadDays: 7
        ])

        showSpotifyWidget = defaults.bool(forKey: Keys.showSpotifyWidget)
        showCalendarWidget = defaults.bool(forKey: Keys.showCalendarWidget)
        showInfoTiles = defaults.bool(forKey: Keys.showInfoTiles)
        showFileShelf = defaults.bool(forKey: Keys.showFileShelf)
        startPinned = defaults.bool(forKey: Keys.startPinned)
        collapseOnHoverExit = defaults.bool(forKey: Keys.collapseOnHoverExit)
        autoShowOnTopHover = defaults.bool(forKey: Keys.autoShowOnTopHover)
        refreshInterval = defaults.double(forKey: Keys.refreshInterval)
        calendarLookaheadDays = defaults.integer(forKey: Keys.calendarLookaheadDays)
    }
}

private enum Keys {
    static let showSpotifyWidget = "showSpotifyWidget"
    static let showCalendarWidget = "showCalendarWidget"
    static let showInfoTiles = "showInfoTiles"
    static let showFileShelf = "showFileShelf"
    static let startPinned = "startPinned"
    static let collapseOnHoverExit = "collapseOnHoverExit"
    static let autoShowOnTopHover = "autoShowOnTopHover"
    static let refreshInterval = "refreshInterval"
    static let calendarLookaheadDays = "calendarLookaheadDays"
}
