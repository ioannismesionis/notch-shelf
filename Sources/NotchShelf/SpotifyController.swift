import AppKit
import Foundation

final class SpotifyController {
    func currentStatus() -> SpotifyStatus {
        guard isSpotifyRunning else {
            return .notRunning
        }

        let script = """
        tell application "Spotify"
            if player state is stopped then
                return {"stopped"}
            end if

            set trackName to name of current track as string
            set trackURI to id of current track as string
            set trackArtist to artist of current track as string
            set trackAlbum to album of current track as string
            set trackArtwork to artwork url of current track as string
            set trackDuration to duration of current track as integer
            set trackPosition to player position as real
            set playbackState to player state as string
            set currentVolume to sound volume as integer
            set shuffleState to shuffling as boolean
            set repeatState to repeating as boolean

            return {"available", playbackState, trackName, trackURI, trackArtist, trackAlbum, trackArtwork, trackDuration as string, trackPosition as string, currentVolume as string, shuffleState as string, repeatState as string}
        end tell
        """

        var error: NSDictionary?
        guard let descriptor = NSAppleScript(source: script)?.executeAndReturnError(&error) else {
            return status(for: error)
        }

        let state = stringValue(at: 1, in: descriptor)
        guard state == "available" else {
            return .noTrack
        }

        let playbackState = SpotifyPlaybackState(rawValue: stringValue(at: 2, in: descriptor)) ?? .unknown
        let durationMilliseconds = Int(stringValue(at: 8, in: descriptor)) ?? 0
        let positionSeconds = Double(stringValue(at: 9, in: descriptor)) ?? 0
        let volume = Int(stringValue(at: 10, in: descriptor)) ?? 0

        let track = SpotifyTrack(
            uri: stringValue(at: 4, in: descriptor),
            title: stringValue(at: 3, in: descriptor),
            artist: stringValue(at: 5, in: descriptor),
            album: stringValue(at: 6, in: descriptor),
            artworkURL: stringValue(at: 7, in: descriptor),
            durationMilliseconds: durationMilliseconds,
            positionSeconds: positionSeconds,
            playbackState: playbackState,
            volume: volume,
            isShuffling: boolValue(at: 11, in: descriptor),
            isRepeating: boolValue(at: 12, in: descriptor),
            artwork: nil
        )

        return SpotifyStatus(availability: .available, track: track)
    }

    func playPause() {
        runCommand("tell application \"Spotify\" to playpause")
    }

    func previousTrack() {
        runCommand("tell application \"Spotify\" to previous track")
    }

    func nextTrack() {
        runCommand("tell application \"Spotify\" to next track")
    }

    func seek(to progress: Double, durationMilliseconds: Int) {
        let durationSeconds = Double(durationMilliseconds) / 1_000
        let position = min(max(progress, 0), 1) * max(durationSeconds, 0)
        let formattedPosition = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), position)
        runCommand("tell application \"Spotify\" to set player position to \(formattedPosition)")
    }

    func setVolume(_ volume: Int) {
        let safeVolume = min(max(volume, 0), 100)
        runCommand("tell application \"Spotify\" to set sound volume to \(safeVolume)")
    }

    func setShuffling(_ isShuffling: Bool) {
        runCommand("tell application \"Spotify\" to set shuffling to \(isShuffling ? "true" : "false")")
    }

    func setRepeating(_ isRepeating: Bool) {
        runCommand("tell application \"Spotify\" to set repeating to \(isRepeating ? "true" : "false")")
    }

    func openSpotify() {
        if let spotifyURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client") {
            NSWorkspace.shared.open(spotifyURL)
            return
        }

        if let webURL = URL(string: "https://open.spotify.com") {
            NSWorkspace.shared.open(webURL)
        }
    }

    private var isSpotifyRunning: Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == "com.spotify.client"
        }
    }

    private func runCommand(_ command: String) {
        guard isSpotifyRunning else {
            openSpotify()
            return
        }

        var error: NSDictionary?
        NSAppleScript(source: command)?.executeAndReturnError(&error)
    }

    private func status(for error: NSDictionary?) -> SpotifyStatus {
        let errorNumber = error?[NSAppleScript.errorNumber] as? Int

        if errorNumber == -1743 || errorNumber == -1744 {
            return .permissionDenied
        }

        let message = error?[NSAppleScript.errorMessage] as? String ?? "Unable to read Spotify"
        return SpotifyStatus(availability: .error(message), track: nil)
    }

    private func stringValue(at index: Int, in descriptor: NSAppleEventDescriptor) -> String {
        descriptor.atIndex(index)?.stringValue ?? ""
    }

    private func boolValue(at index: Int, in descriptor: NSAppleEventDescriptor) -> Bool {
        stringValue(at: index, in: descriptor).lowercased() == "true"
    }
}
