import Foundation
import ServiceManagement

enum LaunchAtLoginController {
    static var isEnabled: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            return true
        case .notRegistered, .notFound:
            return false
        @unknown default:
            return false
        }
    }

    static var statusText: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Waiting for macOS approval"
        case .notRegistered:
            return "Off"
        case .notFound:
            return "Install the app before enabling"
        @unknown default:
            return "Unknown"
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
