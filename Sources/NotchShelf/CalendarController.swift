import AppKit
import EventKit
import Foundation

final class CalendarController {
    private let eventStore = EKEventStore()
    private let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    func currentStatus() -> CalendarStatus {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            return .permissionNeeded
        case .denied:
            return .permissionDenied
        case .restricted:
            return .restricted
        case .authorized, .fullAccess:
            return upcomingEventStatus()
        case .writeOnly:
            return .permissionDenied
        @unknown default:
            return CalendarStatus(availability: .error("Unknown Calendar access state"), event: nil)
        }
    }

    func requestAccess(completion: @escaping (CalendarStatus) -> Void) {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            if let error {
                completion(CalendarStatus(availability: .error(error.localizedDescription), event: nil))
                return
            }

            guard granted, let self else {
                completion(.permissionDenied)
                return
            }

            completion(self.upcomingEventStatus())
        }
    }

    func openCalendar() {
        if let calendarURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
            NSWorkspace.shared.open(calendarURL)
        }
    }

    private func upcomingEventStatus() -> CalendarStatus {
        let now = Date()
        let searchStart = Calendar.current.date(byAdding: .hour, value: -6, to: now) ?? now
        let searchEnd = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        let predicate = eventStore.predicateForEvents(withStart: searchStart, end: searchEnd, calendars: nil)

        let event = eventStore.events(matching: predicate)
            .filter { $0.endDate >= now }
            .filter { $0.status != .canceled }
            .sorted { lhs, rhs in
                if lhs.startDate == rhs.startDate {
                    return lhs.endDate < rhs.endDate
                }

                return lhs.startDate < rhs.startDate
            }
            .first

        guard let event else {
            return .noUpcomingEvents
        }

        return CalendarStatus(availability: .available, event: calendarEvent(from: event))
    }

    private func calendarEvent(from event: EKEvent) -> CalendarEvent {
        CalendarEvent(
            id: event.eventIdentifier ?? UUID().uuidString,
            title: event.title?.isEmpty == false ? event.title : "Untitled event",
            calendarTitle: event.calendar.title,
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay,
            calendarColor: NSColor(cgColor: event.calendar.cgColor) ?? .systemBlue,
            joinURL: meetingURL(for: event)
        )
    }

    private func meetingURL(for event: EKEvent) -> URL? {
        if let url = event.url {
            return url
        }

        let fields = [event.location, event.notes].compactMap { $0 }
        for field in fields {
            if let url = firstURL(in: field) {
                return url
            }
        }

        return nil
    }

    private func firstURL(in text: String) -> URL? {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector?.matches(in: text, options: [], range: range) ?? []

        return matches.compactMap { $0.url }.first { url in
            guard let scheme = url.scheme?.lowercased() else {
                return false
            }

            return scheme == "http" || scheme == "https"
        }
    }
}
