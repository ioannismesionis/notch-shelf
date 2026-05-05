import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    init(settings: AppSettings) {
        let hostingController = NSHostingController(rootView: PreferencesView(settings: settings))
        let window = NSWindow(contentViewController: hostingController)

        window.title = "NotchShelf Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 430, height: 260))
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
