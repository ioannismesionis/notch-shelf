import AppKit

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
    var title: String
    var artist: String
    var album: String
    var artworkURL: String
    var durationMilliseconds: Int
    var positionSeconds: Double
    var playbackState: SpotifyPlaybackState
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
