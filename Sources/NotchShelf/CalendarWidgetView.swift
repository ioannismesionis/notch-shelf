import SwiftUI

struct CalendarWidgetView: View {
    let status: CalendarStatus
    let actions: ShelfActions

    var body: some View {
        Group {
            if let event = status.event {
                eventView(event)
            } else {
                emptyState
            }
        }
        .frame(height: 88)
        .background(Color.white.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func eventView(_ event: CalendarEvent) -> some View {
        HStack(spacing: 12) {
            CalendarBadge(event: event)
                .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(Color(nsColor: event.calendarColor))
                        .frame(width: 7, height: 7)

                    Text(event.calendarTitle)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                        .textCase(.uppercase)
                }

                Text(event.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 8) {
                    Text(event.timeRangeText)
                    Text(event.relativeText)
                        .foregroundStyle(event.isHappeningNow ? Color.white : Color.white.opacity(0.58))
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.66))
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(action: { actions.calendarOpenEvent(event) }) {
                Image(systemName: event.joinURL == nil ? "calendar" : "video.fill")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 38, height: 32)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .help(event.joinURL == nil ? "Open Calendar" : "Join event")
        }
        .padding(12)
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.10))

                Image(systemName: "calendar")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text("Calendar")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
            }

            Spacer()

            Button(action: primaryAction) {
                Image(systemName: primaryIcon)
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 38, height: 32)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .help(primaryHelp)
        }
        .padding(12)
    }

    private var statusText: String {
        switch status.availability {
        case .available:
            return "Ready"
        case .loading:
            return "Requesting access"
        case .permissionNeeded:
            return "Allow access to show events"
        case .permissionDenied:
            return "Calendar access denied"
        case .restricted:
            return "Calendar access restricted"
        case .noUpcomingEvents:
            return "No upcoming events"
        case .error(let message):
            return message
        }
    }

    private var primaryIcon: String {
        switch status.availability {
        case .permissionNeeded:
            return "checkmark"
        default:
            return "calendar"
        }
    }

    private var primaryHelp: String {
        switch status.availability {
        case .permissionNeeded:
            return "Allow Calendar Access"
        default:
            return "Open Calendar"
        }
    }

    private func primaryAction() {
        switch status.availability {
        case .permissionNeeded:
            actions.calendarRequestAccess()
        default:
            actions.calendarOpenApp()
        }
    }
}

private struct CalendarBadge: View {
    let event: CalendarEvent

    var body: some View {
        VStack(spacing: 2) {
            Text(monthText)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.68))
                .textCase(.uppercase)

            Text(dayText)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(nsColor: event.calendarColor).opacity(0.62), lineWidth: 1)
        )
    }

    private var monthText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: event.startDate)
    }

    private var dayText: String {
        let day = Calendar.current.component(.day, from: event.startDate)
        return "\(day)"
    }
}
