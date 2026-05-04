import AppKit
import Combine

final class ShelfStore: ObservableObject {
    @Published var isExpanded = false
    @Published var isPinned = false
    @Published var files: [ShelfItem] = []
    @Published var clipboardPreview = "Clipboard empty"
    @Published var activeApplicationName = "No active app"
    @Published var currentScreenName = "Main display"
    @Published var spotifyStatus = SpotifyStatus.notRunning

    private let spotifyController = SpotifyController()
    private var artworkCache: [String: NSImage] = [:]
    private var artworkURLInFlight: String?

    func refresh() {
        activeApplicationName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "No active app"

        let rawClipboard = NSPasteboard.general.string(forType: .string) ?? ""
        let trimmedClipboard = rawClipboard
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedClipboard.isEmpty {
            clipboardPreview = "Clipboard empty"
        } else if trimmedClipboard.count > 68 {
            clipboardPreview = String(trimmedClipboard.prefix(68)) + "..."
        } else {
            clipboardPreview = trimmedClipboard
        }

        refreshSpotify()
    }

    func addFiles(_ urls: [URL]) {
        let newItems = urls
            .filter { $0.isFileURL }
            .map(ShelfItem.init)
            .filter { item in !files.contains(where: { $0.url == item.url }) }

        files.insert(contentsOf: newItems, at: 0)
        files = Array(files.prefix(8))
    }

    func clearFiles() {
        files.removeAll()
    }

    func spotifyPlayPause() {
        spotifyController.playPause()
        refreshSpotify()
    }

    func spotifyPrevious() {
        spotifyController.previousTrack()
        refreshSpotify()
    }

    func spotifyNext() {
        spotifyController.nextTrack()
        refreshSpotify()
    }

    func openSpotify() {
        spotifyController.openSpotify()
    }

    private func refreshSpotify() {
        var status = spotifyController.currentStatus()

        if var track = status.track {
            if let cachedArtwork = artworkCache[track.artworkURL] {
                track.artwork = cachedArtwork
            } else if let currentTrack = spotifyStatus.track,
                      currentTrack.artworkURL == track.artworkURL {
                track.artwork = currentTrack.artwork
            }

            status.track = track
        }

        spotifyStatus = status
        loadArtworkIfNeeded()
    }

    private func loadArtworkIfNeeded() {
        guard let track = spotifyStatus.track,
              !track.artworkURL.isEmpty,
              track.artwork == nil,
              artworkURLInFlight != track.artworkURL,
              let url = URL(string: track.artworkURL) else {
            return
        }

        let artworkURL = track.artworkURL
        artworkURLInFlight = artworkURL

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data,
                  let image = NSImage(data: data) else {
                DispatchQueue.main.async {
                    if self?.artworkURLInFlight == artworkURL {
                        self?.artworkURLInFlight = nil
                    }
                }
                return
            }

            DispatchQueue.main.async {
                guard let self else { return }
                self.artworkURLInFlight = nil
                self.artworkCache[artworkURL] = image

                guard var track = self.spotifyStatus.track,
                      track.artworkURL == artworkURL else {
                    return
                }

                track.artwork = image
                self.spotifyStatus.track = track
            }
        }.resume()
    }
}

struct ShelfItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL

    var name: String {
        url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
    }

    var location: String {
        url.deletingLastPathComponent().path
    }
}
