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

    private let collapsedSize = CGSize(width: 330, height: 56)
    private let expandedSize = CGSize(width: 540, height: 184)
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
        if store.isPinned {
            ensurePanelVisible(animated: false)
        } else {
            panel.orderOut(nil)
        }
    }

    func toggleExpanded() {
        store.isExpanded ? collapse() : expand()
    }

    func expand() {
        collapseTimer?.invalidate()
        store.isExpanded = true
        ensurePanelVisible(animated: true)
    }

    func collapse() {
        collapseTimer?.invalidate()

        if store.isPinned {
            store.isExpanded = false
            ensurePanelVisible(animated: true)
        } else {
            suppressAutoShowUntilPointerExit = true
            hidePanel(animated: true, collapseAfterHide: true)
        }
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
        settings.startPinned = store.isPinned
        if store.isPinned {
            expand()
        } else {
            evaluatePointerHover()
        }
    }

    func hideFromControl() {
        collapseTimer?.invalidate()
        suppressAutoShowUntilPointerExit = true
        store.isPinned = false
        settings.startPinned = false
        hidePanel(animated: true, collapseAfterHide: true)
    }

    private func configurePanel() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
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
            hidePanel: { [weak self] in self?.hideFromControl() },
            spotifyPlayPause: { [weak self] in self?.store.spotifyPlayPause() },
            spotifyPrevious: { [weak self] in self?.store.spotifyPrevious() },
            spotifyNext: { [weak self] in self?.store.spotifyNext() },
            spotifyOpen: { [weak self] in self?.store.openSpotify() },
            openAutomationSettings: { Self.openAutomationSettings() }
        )

        let hostingView = NSHostingView(rootView: NotchShelfRootView(store: store, actions: actions))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView
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
                    guard let self else { return }

                    self.store.isPinned = self.settings.startPinned
                    self.restartRefreshTimer()

                    if self.store.isPinned {
                        self.expand()
                    } else {
                        self.evaluatePointerHover()
                    }

                    self.updateFrame(animated: true)
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

    private func restartRefreshTimer() {
        refreshTimer?.invalidate()
        store.refresh()
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
        let frame = targetFrame()

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
    }

    private func evaluatePointerHover() {
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
            expand()
        } else if panel.isVisible {
            collapseTimer?.invalidate()
            hidePanel(animated: true, collapseAfterHide: true)
        }
    }

    private func ensurePanelVisible(animated: Bool) {
        guard !panel.isVisible else {
            isHidingPanel = false
            if panel.alphaValue < 1 {
                panel.alphaValue = 1
            }
            updateFrame(animated: animated)
            return
        }

        isHidingPanel = false
        let frame = targetFrame()
        panel.setFrame(animated ? compressedFrame(from: frame) : frame, display: true)
        panel.alphaValue = animated ? 0 : 1
        panel.orderFrontRegardless()

        guard animated else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
            panel.animator().alphaValue = 1
        }
    }

    private func hidePanel(animated: Bool, collapseAfterHide: Bool = false) {
        guard panel.isVisible, !isHidingPanel else { return }

        let hiddenFrame = compressedFrame(from: panel.frame)

        if animated {
            isHidingPanel = true
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(hiddenFrame, display: true)
                panel.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                guard let self, self.isHidingPanel else { return }

                if self.store.isPinned {
                    self.panel.alphaValue = 1
                    self.isHidingPanel = false
                    self.ensurePanelVisible(animated: true)
                    return
                }

                self.panel.orderOut(nil)
                self.panel.alphaValue = 1
                self.isHidingPanel = false

                if collapseAfterHide {
                    self.store.isExpanded = false
                    self.updateFrame(animated: false)
                }
            }
            return
        }

        isHidingPanel = false
        panel.orderOut(nil)
        panel.alphaValue = 1

        if collapseAfterHide {
            store.isExpanded = false
            updateFrame(animated: false)
        }
    }

    private func targetFrame() -> CGRect {
        let size = store.isExpanded ? expandedSize : collapsedSize
        let screen = screenForCurrentPointer()
        let topPadding: CGFloat = store.isExpanded ? 4 : 2

        let origin = CGPoint(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.maxY - size.height - topPadding
        )

        return CGRect(origin: origin, size: size)
    }

    private func compressedFrame(from frame: CGRect) -> CGRect {
        let width = max(120, frame.width - 46)
        let height = max(36, frame.height - 30)

        return CGRect(
            x: frame.midX - width / 2,
            y: frame.maxY - height,
            width: width,
            height: height
        )
    }

    private static func openAutomationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else {
            return
        }

        NSWorkspace.shared.open(url)
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
