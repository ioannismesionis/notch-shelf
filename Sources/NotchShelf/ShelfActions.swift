struct ShelfActions {
    let setHovering: (Bool) -> Void
    let toggleExpanded: () -> Void
    let togglePinned: () -> Void
    let spotifyPlayPause: () -> Void
    let spotifyPrevious: () -> Void
    let spotifyNext: () -> Void
    let spotifyOpen: () -> Void
    let openAutomationSettings: () -> Void
}
