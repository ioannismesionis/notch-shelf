import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: AppSettings

    private let refreshOptions: [Double] = [1, 2, 5, 10]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Preferences")
                .font(.system(size: 20, weight: .bold))

            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Widgets")

                Toggle("Spotify", isOn: $settings.showSpotifyWidget)
                Toggle("Calendar", isOn: $settings.showCalendarWidget)
                Toggle("Info tiles", isOn: $settings.showInfoTiles)
                Toggle("File shelf", isOn: $settings.showFileShelf)
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Panel")

                Toggle("Start pinned", isOn: $settings.startPinned)
                Toggle("Collapse after hover", isOn: $settings.collapseOnHoverExit)
                Toggle("Show on top hover", isOn: $settings.autoShowOnTopHover)
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Refresh")

                Picker("Interval", selection: $settings.refreshInterval) {
                    ForEach(refreshOptions, id: \.self) { option in
                        Text(refreshLabel(for: option)).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Stepper(
                    "Calendar lookahead: \(settings.calendarLookaheadDays) days",
                    value: $settings.calendarLookaheadDays,
                    in: 1...30
                )
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 430, height: 420, alignment: .topLeading)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func refreshLabel(for seconds: Double) -> String {
        if seconds == 1 {
            return "1 sec"
        }

        return "\(Int(seconds)) sec"
    }
}
