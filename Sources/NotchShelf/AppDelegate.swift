import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panelController: NotchPanelController?
    private var preferencesWindowController: PreferencesWindowController?
    private let keyboardShortcutController = KeyboardShortcutController.shared
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = NotchPanelController()
        self.panelController = controller

        configureStatusItem()
        configureKeyboardShortcut()
        controller.show()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "rectangle.topthird.inset.filled",
            accessibilityDescription: "NotchShelf"
        )
        item.button?.target = self
        item.button?.action = #selector(toggleExpanded)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Expand NotchShelf", action: #selector(expand), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Collapse NotchShelf", action: #selector(collapse), keyEquivalent: "c"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit NotchShelf", action: #selector(quit), keyEquivalent: "q"))

        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    private func configureKeyboardShortcut() {
        keyboardShortcutController.onHotKey = { [weak self] in
            self?.panelController?.toggleFromKeyboardShortcut()
        }

        AppSettings.shared.$globalShortcutEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                self?.keyboardShortcutController.setEnabled(isEnabled)
            }
            .store(in: &cancellables)
    }

    @objc private func toggleExpanded() {
        panelController?.toggleExpanded()
    }

    @objc private func expand() {
        panelController?.expand()
    }

    @objc private func collapse() {
        panelController?.collapse()
    }

    @objc private func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(settings: .shared)
        }

        preferencesWindowController?.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
