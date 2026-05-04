import Foundation

struct ShelfActions {
    let setHovering: (Bool) -> Void
    let toggleExpanded: () -> Void
    let togglePinned: () -> Void
    let addFiles: ([URL]) -> Void
    let clearFiles: () -> Void
    let openFile: (ShelfItem) -> Void
    let revealFile: (ShelfItem) -> Void
    let spotifyPlayPause: () -> Void
    let spotifyPrevious: () -> Void
    let spotifyNext: () -> Void
    let spotifyOpen: () -> Void
}
