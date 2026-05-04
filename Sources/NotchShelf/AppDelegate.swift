import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panelController: NotchPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = NotchPanelController()
        self.panelController = controller

        configureStatusItem()
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
        menu.addItem(NSMenuItem(title: "Clear File Shelf", action: #selector(clearShelf), keyEquivalent: "k"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit NotchShelf", action: #selector(quit), keyEquivalent: "q"))

        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
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

    @objc private func clearShelf() {
        panelController?.store.clearFiles()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
