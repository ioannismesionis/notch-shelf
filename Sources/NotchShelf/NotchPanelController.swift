import AppKit
import Combine
import SwiftUI

final class NotchPanelController: NSObject {
    let settings = AppSettings.shared
    let store: ShelfStore

    private let panel: NotchPanel
    private var cancellables = Set<AnyCancellable>()
    private var collapseTimer: Timer?
    private var refreshTimer: Timer?
    private var pointerTrackingTimer: Timer?
    private var isHidingPanel = false
    private var suppressAutoShowUntilPointerExit = false

    private let collapsedSize = CGSize(width: 310, height: 38)
    private let expandedWidth: CGFloat = 520
    private let topHoverTriggerSize = CGSize(width: 380, height: 34)

    override init() {
        store = ShelfStore(settings: settings)
        panel = NotchPanel(
            contentRect: CGRect(origin: .zero, size: collapsedSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()

        if settings.startPinned {
            store.isExpanded = true
        }

        configurePanel()
        bindStore()
        observeScreens()
        startRefreshTimer()
        startPointerTracking()
    }

    func show() {
        updateFrame(animated: false)
        if settings.autoShowOnTopHover, !store.isPinned {
            panel.orderOut(nil)
        } else {
            ensurePanelVisible(animated: false)
        }
    }

    func toggleExpanded() {
        store.isExpanded ? collapse() : expand()
    }

    func expand() {
        collapseTimer?.invalidate()
        ensurePanelVisible(animated: true)
        store.isExpanded = true
    }

    func collapse() {
        collapseTimer?.invalidate()
        if store.isPinned {
            store.isPinned = false
            settings.startPinned = false
        }

        store.isExpanded = false

        if settings.autoShowOnTopHover {
            suppressAutoShowUntilPointerExit = true
            updateFrame(animated: true)
            hidePanel(animated: true)
        }
    }

    func setHovering(_ isHovering: Bool) {
        collapseTimer?.invalidate()

        if isHovering {
            expand()
            return
        }

        guard settings.collapseOnHoverExit, !store.isPinned else { return }
        collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.collapse()
            }
        }
    }

    func togglePinned() {
        store.isPinned.toggle()
        settings.startPinned = store.isPinned
        if store.isPinned {
            expand()
        } else {
            evaluatePointerHover()
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
            spotifyOpen: { [weak self] in self?.store.openSpotify() },
            calendarRequestAccess: { [weak self] in self?.store.requestCalendarAccess() },
            calendarOpenEvent: { [weak self] event in self?.store.openCalendarEvent(event) },
            calendarOpenApp: { [weak self] in self?.store.openCalendarApp() }
        )

        panel.contentView = NSHostingView(rootView: NotchShelfRootView(store: store, settings: settings, actions: actions))
    }

    private func bindStore() {
        store.$isExpanded
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateFrame(animated: true)
            }
            .store(in: &cancellables)

        settings.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.store.isPinned = self?.settings.startPinned ?? false
                    self?.restartRefreshTimer(forceCalendar: true)
                    self?.evaluatePointerHover()
                    self?.updateFrame(animated: true)
                }
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
        restartRefreshTimer()
    }

    private func startPointerTracking() {
        pointerTrackingTimer?.invalidate()
        pointerTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.evaluatePointerHover()
            }
        }
    }

    private func restartRefreshTimer(forceCalendar: Bool = false) {
        refreshTimer?.invalidate()
        store.refresh(forceCalendar: forceCalendar)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: max(1.0, settings.refreshInterval), repeats: true) { [weak self] _ in
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
        let size = store.isExpanded ? expandedSize() : collapsedSize
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

    private func evaluatePointerHover() {
        guard settings.autoShowOnTopHover else {
            if !panel.isVisible {
                ensurePanelVisible(animated: false)
            }
            return
        }

        guard !store.isPinned else {
            if !panel.isVisible {
                ensurePanelVisible(animated: false)
            }
            return
        }

        let pointer = NSEvent.mouseLocation
        let screen = screen(containing: pointer)
        let isInTriggerZone = topHoverTriggerRect(for: screen).contains(pointer)
        let isInPanelZone = panel.frame.insetBy(dx: -8, dy: -8).contains(pointer)

        if suppressAutoShowUntilPointerExit {
            if isInTriggerZone || isInPanelZone {
                return
            }

            suppressAutoShowUntilPointerExit = false
        }

        let shouldShow = isInTriggerZone || isInPanelZone

        if shouldShow {
            ensurePanelVisible(animated: true)
            if !store.isExpanded {
                expand()
            }
        } else if panel.isVisible {
            collapseTimer?.invalidate()
            store.isExpanded = false
            updateFrame(animated: true)
            hidePanel(animated: true)
        }
    }

    private func ensurePanelVisible(animated: Bool) {
        guard !panel.isVisible else {
            isHidingPanel = false
            if panel.alphaValue < 1 {
                panel.alphaValue = 1
            }
            return
        }

        isHidingPanel = false
        updateFrame(animated: false)
        panel.alphaValue = animated ? 0 : 1
        panel.orderFrontRegardless()

        guard animated else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1
        }
    }

    private func hidePanel(animated: Bool) {
        guard panel.isVisible, !isHidingPanel else { return }

        if animated {
            isHidingPanel = true
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                panel.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                guard let self, self.isHidingPanel, !self.store.isPinned else { return }
                self.panel.orderOut(nil)
                self.panel.alphaValue = 1
                self.isHidingPanel = false
            }
            return
        }

        isHidingPanel = false
        panel.orderOut(nil)
        panel.alphaValue = 1
    }

    private func expandedSize() -> CGSize {
        var height: CGFloat = 72

        if settings.showSpotifyWidget {
            height += 109
        }

        if settings.showCalendarWidget {
            height += 101
        }

        if settings.showInfoTiles {
            height += 126
        }

        if settings.showFileShelf {
            height += 112
        }

        return CGSize(width: expandedWidth, height: max(188, height))
    }

    private func screenForCurrentPointer() -> NSScreen {
        let pointer = NSEvent.mouseLocation
        return screen(containing: pointer)
    }

    private func screen(containing point: CGPoint) -> NSScreen {
        NSScreen.screens.first { $0.frame.contains(point) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
            ?? NSScreen()
    }

    private func topHoverTriggerRect(for screen: NSScreen) -> CGRect {
        CGRect(
            x: screen.frame.midX - topHoverTriggerSize.width / 2,
            y: screen.frame.maxY - topHoverTriggerSize.height,
            width: topHoverTriggerSize.width,
            height: topHoverTriggerSize.height
        )
    }
}

final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
