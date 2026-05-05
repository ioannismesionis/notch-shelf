import AppKit
import Combine

final class ShelfStore: ObservableObject {
    @Published var isExpanded = false
    @Published var isPinned = false
    @Published var spotifyStatus = SpotifyStatus.notRunning
    @Published var savedTrackStatus = SpotifySavedTrackStatus.unavailable

    private let spotifyController = SpotifyController()
    private let spotifyWebAPIClient = SpotifyWebAPIClient()
    private let settings: AppSettings
    private var artworkCache: [String: NSImage] = [:]
    private var artworkURLInFlight: String?
    private var savedTrackURIInFlight: String?
    private var lastSavedTrackURI: String?

    init(settings: AppSettings = .shared) {
        self.settings = settings
        isPinned = settings.startPinned
    }

    func refresh() {
        refreshSpotify()
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

    func spotifyToggleSavedTrack() {
        guard let uri = spotifyStatus.track?.uri, !uri.isEmpty else {
            savedTrackStatus = .unavailable
            return
        }

        let clientID = settings.spotifyClientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clientID.isEmpty else {
            savedTrackStatus = .needsClientID
            return
        }

        let targetStatus = savedTrackStatus

        if !spotifyWebAPIClient.hasToken() {
            savedTrackStatus = .authorizing
            spotifyWebAPIClient.authorize(clientID: clientID) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success:
                    guard self.spotifyStatus.track?.uri == uri else {
                        self.savedTrackStatus = .unavailable
                        self.refreshSavedTrackStatus(for: self.spotifyStatus.track?.uri)
                        return
                    }

                    self.saveTrack(uri, clientID: clientID)
                case .failure(let error):
                    self.savedTrackStatus = .error(Self.message(for: error))
                }
            }
            return
        }

        if targetStatus == .saved {
            removeTrack(uri, clientID: clientID)
        } else {
            saveTrack(uri, clientID: clientID)
        }
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
        refreshSavedTrackStatus(for: status.track?.uri)
        loadArtworkIfNeeded()
    }

    private func refreshSavedTrackStatus(for uri: String?) {
        guard !savedTrackStatus.isWorking else { return }

        guard let uri, !uri.isEmpty else {
            savedTrackStatus = .unavailable
            lastSavedTrackURI = nil
            return
        }

        let clientID = settings.spotifyClientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clientID.isEmpty else {
            savedTrackStatus = .needsClientID
            lastSavedTrackURI = nil
            return
        }

        guard spotifyWebAPIClient.hasToken() else {
            savedTrackStatus = .needsAuthorization
            lastSavedTrackURI = nil
            return
        }

        if lastSavedTrackURI == uri,
           savedTrackURIInFlight == nil,
           savedTrackStatus == .saved || savedTrackStatus == .notSaved {
            return
        }

        guard savedTrackURIInFlight != uri else { return }

        savedTrackURIInFlight = uri
        savedTrackStatus = .checking

        spotifyWebAPIClient.checkSaved(uri: uri, clientID: clientID) { [weak self] result in
            guard let self else { return }
            self.savedTrackURIInFlight = nil

            guard self.spotifyStatus.track?.uri == uri else {
                self.savedTrackStatus = .unavailable
                self.refreshSavedTrackStatus(for: self.spotifyStatus.track?.uri)
                return
            }

            self.lastSavedTrackURI = uri

            switch result {
            case .success(let isSaved):
                self.savedTrackStatus = isSaved ? .saved : .notSaved
            case .failure(let error):
                self.savedTrackStatus = .error(Self.message(for: error))
            }
        }
    }

    private func saveTrack(_ uri: String, clientID: String) {
        savedTrackStatus = .updating
        spotifyWebAPIClient.save(uri: uri, clientID: clientID) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                guard self.spotifyStatus.track?.uri == uri else {
                    self.savedTrackStatus = .unavailable
                    self.refreshSavedTrackStatus(for: self.spotifyStatus.track?.uri)
                    return
                }

                self.lastSavedTrackURI = uri
                self.savedTrackStatus = .saved
            case .failure(let error):
                self.savedTrackStatus = .error(Self.message(for: error))
            }
        }
    }

    private func removeTrack(_ uri: String, clientID: String) {
        savedTrackStatus = .updating
        spotifyWebAPIClient.remove(uri: uri, clientID: clientID) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                guard self.spotifyStatus.track?.uri == uri else {
                    self.savedTrackStatus = .unavailable
                    self.refreshSavedTrackStatus(for: self.spotifyStatus.track?.uri)
                    return
                }

                self.lastSavedTrackURI = uri
                self.savedTrackStatus = .notSaved
            case .failure(let error):
                self.savedTrackStatus = .error(Self.message(for: error))
            }
        }
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

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
