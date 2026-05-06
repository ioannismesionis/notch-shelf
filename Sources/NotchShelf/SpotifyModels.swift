import AppKit
import Foundation

enum SpotifyAvailability: Equatable {
    case available
    case notRunning
    case noTrack
    case permissionDenied
    case error(String)
}

enum SpotifyPlaybackState: String, Equatable {
    case playing
    case paused
    case stopped
    case unknown

    var isPlaying: Bool {
        self == .playing
    }
}

struct SpotifyTrack {
    var uri: String
    var title: String
    var artist: String
    var album: String
    var artworkURL: String
    var durationMilliseconds: Int
    var positionSeconds: Double
    var playbackState: SpotifyPlaybackState
    var volume: Int
    var isShuffling: Bool
    var isRepeating: Bool
    var artwork: NSImage?

    var durationSeconds: Double {
        Double(durationMilliseconds) / 1_000
    }

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(max(positionSeconds / durationSeconds, 0), 1)
    }

    var remainingText: String {
        let remaining = max(Int(durationSeconds - positionSeconds), 0)
        return "-\(Self.format(seconds: remaining))"
    }

    var elapsedText: String {
        Self.format(seconds: max(Int(positionSeconds), 0))
    }

    static func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

enum SpotifySavedTrackStatus: Equatable {
    case unavailable
    case needsClientID
    case needsAuthorization
    case authorizing
    case checking
    case saved
    case notSaved
    case updating
    case error(String)

    var isSaved: Bool {
        self == .saved
    }

    var isWorking: Bool {
        switch self {
        case .authorizing, .checking, .updating:
            return true
        default:
            return false
        }
    }

    var helpText: String {
        switch self {
        case .unavailable:
            return "No Spotify track"
        case .needsClientID:
            return "Add Spotify Client ID in Preferences"
        case .needsAuthorization:
            return "Connect Spotify library"
        case .authorizing:
            return "Connecting Spotify"
        case .checking:
            return "Checking Liked Songs"
        case .saved:
            return "Remove from Liked Songs"
        case .notSaved:
            return "Save to Liked Songs"
        case .updating:
            return "Updating Liked Songs"
        case .error(let message):
            return message
        }
    }
}

struct SpotifyStatus {
    var availability: SpotifyAvailability
    var track: SpotifyTrack?

    static let notRunning = SpotifyStatus(availability: .notRunning, track: nil)
    static let noTrack = SpotifyStatus(availability: .noTrack, track: nil)
    static let permissionDenied = SpotifyStatus(availability: .permissionDenied, track: nil)

    var isAvailable: Bool {
        availability == .available
    }
}

struct SpotifyPlaylist: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var uri: String
    var ownerName: String
    var trackCount: Int
    var artworkURL: String?

    var subtitle: String {
        if ownerName.isEmpty {
            return "\(trackCount) tracks"
        }

        return "\(ownerName) • \(trackCount) tracks"
    }
}
