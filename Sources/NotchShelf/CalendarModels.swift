import AppKit
import Foundation

enum CalendarAvailability: Equatable {
    case available
    case loading
    case permissionNeeded
    case permissionDenied
    case restricted
    case noUpcomingEvents
    case error(String)
}

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let calendarTitle: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarColor: NSColor
    let joinURL: URL?

    var isHappeningNow: Bool {
        let now = Date()
        return startDate <= now && now <= endDate
    }

    var timeRangeText: String {
        if isAllDay {
            return "All day"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var relativeText: String {
        let now = Date()

        if isHappeningNow {
            let minutesLeft = max(Int(endDate.timeIntervalSince(now) / 60), 0)
            if minutesLeft < 1 {
                return "Ending now"
            }

            return "Now, \(minutesLeft)m left"
        }

        let minutesUntil = Int(startDate.timeIntervalSince(now) / 60)
        if minutesUntil < 1 {
            return "Starting now"
        }

        if minutesUntil < 60 {
            return "In \(minutesUntil)m"
        }

        let hours = minutesUntil / 60
        let minutes = minutesUntil % 60
        if hours < 24 {
            return minutes == 0 ? "In \(hours)h" : "In \(hours)h \(minutes)m"
        }

        let days = hours / 24
        return days == 1 ? "Tomorrow" : "In \(days)d"
    }
}

struct CalendarStatus {
    var availability: CalendarAvailability
    var event: CalendarEvent?

    static let permissionNeeded = CalendarStatus(availability: .permissionNeeded, event: nil)
    static let permissionDenied = CalendarStatus(availability: .permissionDenied, event: nil)
    static let restricted = CalendarStatus(availability: .restricted, event: nil)
    static let noUpcomingEvents = CalendarStatus(availability: .noUpcomingEvents, event: nil)
}
