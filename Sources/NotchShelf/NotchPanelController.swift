import AppKit
import Combine
import SwiftUI

final class NotchPanelController: NSObject {
    let store = ShelfStore()

    private let panel: NotchPanel
    private var cancellables = Set<AnyCancellable>()
    private var collapseTimer: Timer?
    private var refreshTimer: Timer?

    private let collapsedSize = CGSize(width: 310, height: 38)
    private let expandedSize = CGSize(width: 520, height: 430)

    override init() {
        panel = NotchPanel(
            contentRect: CGRect(origin: .zero, size: collapsedSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()

        configurePanel()
        bindStore()
        observeScreens()
        startRefreshTimer()
    }

    func show() {
        updateFrame(animated: false)
        panel.orderFrontRegardless()
    }

    func toggleExpanded() {
        store.isExpanded ? collapse() : expand()
    }

    func expand() {
        collapseTimer?.invalidate()
        store.isExpanded = true
    }

    func collapse() {
        guard !store.isPinned else { return }
        store.isExpanded = false
    }

    func setHovering(_ isHovering: Bool) {
        collapseTimer?.invalidate()

        if isHovering {
            expand()
            return
        }

        guard !store.isPinned else { return }
        collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.collapse()
            }
        }
    }

    func togglePinned() {
        store.isPinned.toggle()
        if store.isPinned {
            expand()
        }
    }

    func open(_ item: ShelfItem) {
        NSWorkspace.shared.open(item.url)
    }

    func reveal(_ item: ShelfItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    private func configurePanel() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        let actions = ShelfActions(
            setHovering: { [weak self] isHovering in self?.setHovering(isHovering) },
            toggleExpanded: { [weak self] in self?.toggleExpanded() },
            togglePinned: { [weak self] in self?.togglePinned() },
            addFiles: { [weak self] urls in self?.store.addFiles(urls) },
            clearFiles: { [weak self] in self?.store.clearFiles() },
            openFile: { [weak self] item in self?.open(item) },
            revealFile: { [weak self] item in self?.reveal(item) },
            spotifyPlayPause: { [weak self] in self?.store.spotifyPlayPause() },
            spotifyPrevious: { [weak self] in self?.store.spotifyPrevious() },
            spotifyNext: { [weak self] in self?.store.spotifyNext() },
            spotifyOpen: { [weak self] in self?.store.openSpotify() }
        )

        panel.contentView = NSHostingView(rootView: NotchShelfRootView(store: store, actions: actions))
    }

    private func bindStore() {
        store.$isExpanded
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateFrame(animated: true)
            }
            .store(in: &cancellables)
    }

    private func observeScreens() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func startRefreshTimer() {
        store.refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.store.refresh()
                self?.updateFrame(animated: true)
            }
        }
    }

    @objc private func screenParametersDidChange() {
        store.refresh()
        updateFrame(animated: true)
    }

    private func updateFrame(animated: Bool) {
        let size = store.isExpanded ? expandedSize : collapsedSize
        let screen = screenForCurrentPointer()
        let topPadding: CGFloat = store.isExpanded ? 9 : 6

        store.currentScreenName = screen.localizedName

        let origin = CGPoint(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.maxY - size.height - topPadding
        )
        let frame = CGRect(origin: origin, size: size)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
    }

    private func screenForCurrentPointer() -> NSScreen {
        let pointer = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(pointer) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
            ?? NSScreen()
    }
}

final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
