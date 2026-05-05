struct ShelfActions {
    let setHovering: (Bool) -> Void
    let toggleExpanded: () -> Void
    let togglePinned: () -> Void
    let spotifyPlayPause: () -> Void
    let spotifyPrevious: () -> Void
    let spotifyNext: () -> Void
    let spotifyOpen: () -> Void
    let spotifyToggleSavedTrack: () -> Void
    let spotifySeek: (Double) -> Void
    let spotifySetVolume: (Double) -> Void
    let spotifyToggleShuffle: () -> Void
    let spotifyToggleRepeat: () -> Void
    let openAutomationSettings: () -> Void
}
