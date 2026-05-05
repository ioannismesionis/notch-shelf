import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: AppSettings

    private let refreshOptions: [Double] = [1, 2, 5, 10]

    @State private var launchAtLoginEnabled = LaunchAtLoginController.isEnabled
    @State private var launchAtLoginStatus = LaunchAtLoginController.statusText
    @State private var launchAtLoginError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Preferences")
                .font(.system(size: 20, weight: .bold))

            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Panel")

                Toggle("Start pinned", isOn: $settings.startPinned)
                Toggle("Open at login", isOn: launchAtLoginBinding)

                Text("Launch at login: \(launchAtLoginStatus)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(launchAtLoginError == nil ? Color.secondary : Color.red)

                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red)
                }

                Toggle("Option-Space shortcut", isOn: $settings.globalShortcutEnabled)

                Text("Shows NotchShelf expanded. Press again to hide or collapse it.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
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

                TextField("Spotify Client ID", text: $settings.spotifyClientID)
                    .textFieldStyle(.roundedBorder)

                Text("Redirect URI: notchshelf://spotify-auth")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 430, height: 400, alignment: .topLeading)
        .onAppear(perform: refreshLaunchAtLoginState)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLoginEnabled },
            set: { enabled in
                updateLaunchAtLogin(enabled)
            }
        )
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginError = nil

        do {
            try LaunchAtLoginController.setEnabled(enabled)
        } catch {
            launchAtLoginError = error.localizedDescription
        }

        refreshLaunchAtLoginState()
    }

    private func refreshLaunchAtLoginState() {
        launchAtLoginEnabled = LaunchAtLoginController.isEnabled
        launchAtLoginStatus = LaunchAtLoginController.statusText
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
