import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: AppSettings

    private let refreshOptions: [Double] = [1, 2, 5, 10]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Preferences")
                .font(.system(size: 20, weight: .bold))

            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Panel")

                Toggle("Start pinned", isOn: $settings.startPinned)
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Spotify")

                Picker("Refresh interval", selection: $settings.refreshInterval) {
                    ForEach(refreshOptions, id: \.self) { option in
                        Text(refreshLabel(for: option)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 430, height: 220, alignment: .topLeading)
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
