import AppKit
import Combine
import SwiftUI

final class NotchPanelController: NSObject {
    let settings = AppSettings.shared
    let store: ShelfStore
    var openPreferences: (() -> Void)?

    private let panel: NotchPanel
    private var cancellables = Set<AnyCancellable>()
    private var collapseTimer: Timer?
    private var refreshTimer: Timer?
    private var pointerTrackingTimer: Timer?
    private var isHidingPanel = false
    private var suppressAutoShowUntilPointerExit = false
    private var shouldExpandOnNextHover = true
    private var manualPanelCenter: CGPoint?
    private var activeScreenID: CGDirectDisplayID?
    private var dragStartFrame: CGRect?
    private var dragStartMouseLocation: CGPoint?

    private let collapsedSize = CGSize(width: 180, height: 162)
    private let expandedSize = CGSize(width: 580, height: 204)
    private let expandedWithPlaylistsSize = CGSize(width: 610, height: 254)
    private let setupSize = CGSize(width: 640, height: 438)
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

        if store.isFirstRunSetupVisible {
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
        if store.isPinned || store.isFirstRunSetupVisible {
            ensurePanelVisible(animated: false)
        } else {
            panel.orderOut(nil)
        }
    }

    func toggleExpanded() {
        store.isExpanded ? collapseToMiniPlayer() : expand()
    }

    func toggleFromKeyboardShortcut() {
        collapseTimer?.invalidate()

        if panel.isVisible, store.isExpanded {
            if store.isPinned {
                collapse()
            } else {
                suppressAutoShowUntilPointerExit = true
                hidePanel(animated: true, collapseAfterHide: true)
            }
            return
        }

        expand()
    }

    func expand() {
        collapseTimer?.invalidate()
        suppressAutoShowUntilPointerExit = false
        shouldExpandOnNextHover = true
        store.isExpanded = true
        ensurePanelVisible(animated: true)
    }

    func collapse() {
        collapseToMiniPlayer()
    }

    func collapseToMiniPlayer() {
        collapseTimer?.invalidate()
        suppressAutoShowUntilPointerExit = true
        shouldExpandOnNextHover = false
        store.isExpanded = false
        ensurePanelVisible(animated: true)
    }

    func setHovering(_ isHovering: Bool) {
        collapseTimer?.invalidate()

        if isHovering {
            if isHidingPanel {
                ensurePanelVisible(animated: true)
            }
            return
        }

        guard !store.isPinned, !store.isFirstRunSetupVisible else { return }
        collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.hidePanel(animated: true, collapseAfterHide: true)
            }
        }
    }

    func togglePinned() {
        store.isPinned.toggle()
        settings.startPinned = store.isPinned
        if store.isPinned {
            activateScreen(containing: panel.frame.center)
            expand()
        } else {
            manualPanelCenter = nil
            activeScreenID = nil
            dragStartFrame = nil
            dragStartMouseLocation = nil
            store.isManuallyPositioned = false
            evaluatePointerHover()
        }
    }

    func beginPanelDrag() {
        guard panel.isVisible else { return }

        collapseTimer?.invalidate()
        dragStartFrame = panel.frame
        dragStartMouseLocation = NSEvent.mouseLocation
        manualPanelCenter = panel.frame.center
        activateScreen(containing: panel.frame.center)

        if !store.isPinned {
            store.isPinned = true
        }
    }

    func dragPanel() {
        guard let dragStartFrame,
              let dragStartMouseLocation else { return }

        let mouseLocation = NSEvent.mouseLocation
        let proposedFrame = dragStartFrame.offsetBy(
            dx: mouseLocation.x - dragStartMouseLocation.x,
            dy: mouseLocation.y - dragStartMouseLocation.y
        )
        let screen = screen(containing: mouseLocation)
        let frame = clampedFrame(proposedFrame, on: screen)

        activeScreenID = screenID(for: screen)
        manualPanelCenter = frame.center
        store.isManuallyPositioned = true
        panel.setFrame(frame, display: true)
    }

    func endPanelDrag() {
        dragStartFrame = nil
        dragStartMouseLocation = nil

        if !settings.startPinned {
            settings.startPinned = true
        }
    }

    func resetPanelPosition() {
        collapseTimer?.invalidate()
        dragStartFrame = nil
        dragStartMouseLocation = nil
        activateScreen(containing: panel.frame.center)
        manualPanelCenter = nil
        store.isManuallyPositioned = false
        ensurePanelVisible(animated: true)
    }

    private func configurePanel() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.level = .statusBar
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        let actions = ShelfActions(
            setHovering: { [weak self] isHovering in self?.setHovering(isHovering) },
            beginPanelDrag: { [weak self] in self?.beginPanelDrag() },
            dragPanel: { [weak self] in self?.dragPanel() },
            endPanelDrag: { [weak self] in self?.endPanelDrag() },
            resetPanelPosition: { [weak self] in self?.resetPanelPosition() },
            toggleExpanded: { [weak self] in self?.toggleExpanded() },
            togglePinned: { [weak self] in self?.togglePinned() },
            spotifyPlayPause: { [weak self] in self?.store.spotifyPlayPause() },
            spotifyPrevious: { [weak self] in self?.store.spotifyPrevious() },
            spotifyNext: { [weak self] in self?.store.spotifyNext() },
            spotifyOpen: { [weak self] in self?.store.openSpotify() },
            spotifyToggleSavedTrack: { [weak self] in self?.store.spotifyToggleSavedTrack() },
            spotifySeek: { [weak self] progress in self?.store.spotifySeek(to: progress) },
            spotifySetVolume: { [weak self] volume in self?.store.spotifySetVolume(volume) },
            spotifyToggleShuffle: { [weak self] in self?.store.spotifyToggleShuffle() },
            spotifyToggleRepeat: { [weak self] in self?.store.spotifyToggleRepeat() },
            spotifyAuthorizeLibrary: { [weak self] in self?.store.spotifyAuthorizeLibrary() },
            spotifyOpenPlaylist: { [weak self] playlist in self?.store.openPlaylist(playlist) },
            openPreferences: { [weak self] in self?.openPreferences?() },
            openAutomationSettings: { Self.openAutomationSettings() },
            enableLaunchAtLogin: { [weak self] in self?.enableLaunchAtLogin() },
            completeFirstRunSetup: { [weak self] in
                self?.store.completeFirstRunSetup()
                self?.evaluatePointerHover()
            }
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

        store.$isFirstRunSetupVisible
            .removeDuplicates()
            .sink { [weak self] isVisible in
                guard let self else { return }

                if isVisible {
                    self.expand()
                } else if !self.store.isPinned {
                    self.evaluatePointerHover()
                }

                self.updateFrame(animated: true)
            }
            .store(in: &cancellables)

        settings.$firstRunSetupCompleted
            .removeDuplicates()
            .sink { [weak self] isCompleted in
                guard let self else { return }

                self.store.isFirstRunSetupVisible = !isCompleted
            }
            .store(in: &cancellables)

        settings.$startPinned
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] isPinned in
                guard let self else { return }

                self.store.isPinned = isPinned

                if isPinned {
                    if self.activeScreenID == nil {
                        self.activateScreen(containing: self.panel.frame.center)
                    }
                    self.ensurePanelVisible(animated: true)
                } else {
                    self.manualPanelCenter = nil
                    self.activeScreenID = nil
                    self.dragStartFrame = nil
                    self.dragStartMouseLocation = nil
                    self.store.isManuallyPositioned = false
                    self.evaluatePointerHover()
                }
            }
            .store(in: &cancellables)

        settings.$refreshInterval
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.restartRefreshTimer()
            }
            .store(in: &cancellables)

        settings.$spotifyClientID
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.store.refreshSetupStatus()
            }
            .store(in: &cancellables)

        settings.$pinnedPlaylists
            .dropFirst()
            .sink { [weak self] playlists in
                guard let self else { return }

                self.store.pinnedPlaylists = playlists
                self.updateFrame(animated: true)
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
        reconcileActiveScreen()
        updateFrame(animated: true)
    }

    private func updateFrame(animated: Bool) {
        guard dragStartFrame == nil else { return }

        let frame = targetFrame()

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = store.isExpanded ? 0.28 : 0.22
                context.timingFunction = CAMediaTimingFunction(
                    name: store.isExpanded ? .easeOut : .easeInEaseOut
                )
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
    }

    private func evaluatePointerHover() {
        guard !store.isFirstRunSetupVisible else {
            if !panel.isVisible {
                activateScreenForCurrentPointer()
                ensurePanelVisible(animated: false)
            }
            return
        }

        guard !store.isPinned else {
            if !panel.isVisible {
                if activeScreenID == nil {
                    activateScreenForCurrentPointer()
                }
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
            if !panel.isVisible {
                activeScreenID = screenID(for: screen)
                showPreferredHoverState()
            } else if store.isExpanded {
                ensurePanelVisible(animated: false)
            }
        } else if panel.isVisible {
            collapseTimer?.invalidate()
            hidePanel(animated: true, collapseAfterHide: true)
        }
    }

    private func ensurePanelVisible(animated: Bool) {
        if activeScreenID == nil {
            activateScreen(containing: panel.isVisible ? panel.frame.center : NSEvent.mouseLocation)
        }

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
        panel.setFrame(animated ? notchSeedFrame(from: frame) : frame, display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        guard animated else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(frame, display: true)
            panel.animator().alphaValue = 1
        }
    }

    private func showPreferredHoverState() {
        if shouldExpandOnNextHover {
            expand()
            return
        }

        collapseTimer?.invalidate()
        store.isExpanded = false
        ensurePanelVisible(animated: true)
    }

    private func hidePanel(animated: Bool, collapseAfterHide: Bool = false) {
        guard panel.isVisible, !isHidingPanel else { return }

        let hiddenFrame = notchSeedFrame(from: panel.frame)

        if animated {
            isHidingPanel = true
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
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
        let size = targetSize()

        if let manualPanelCenter {
            let screen = screen(containing: manualPanelCenter)
            return clampedFrame(
                CGRect(
                    x: manualPanelCenter.x - size.width / 2,
                    y: manualPanelCenter.y - size.height / 2,
                    width: size.width,
                    height: size.height
                ),
                on: screen
            )
        }

        let screen = activeScreen() ?? screenForCurrentPointer()
        let topPadding = targetTopPadding()

        let origin = CGPoint(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.maxY - size.height - topPadding
        )

        return CGRect(origin: origin, size: size)
    }

    private func clampedFrame(_ frame: CGRect, on screen: NSScreen) -> CGRect {
        let bounds = screen.visibleFrame.insetBy(dx: 8, dy: 8)
        let x = clamped(
            frame.origin.x,
            lowerBound: bounds.minX,
            upperBound: bounds.maxX - frame.width,
            fallback: bounds.midX - frame.width / 2
        )
        let y = clamped(
            frame.origin.y,
            lowerBound: bounds.minY,
            upperBound: bounds.maxY - frame.height,
            fallback: bounds.midY - frame.height / 2
        )

        return CGRect(origin: CGPoint(x: x, y: y), size: frame.size)
    }

    private func clamped(
        _ value: CGFloat,
        lowerBound: CGFloat,
        upperBound: CGFloat,
        fallback: CGFloat
    ) -> CGFloat {
        guard lowerBound <= upperBound else { return fallback }
        return min(max(value, lowerBound), upperBound)
    }

    private func targetTopPadding() -> CGFloat {
        if store.isFirstRunSetupVisible || store.isExpanded {
            return 2
        }

        // The collapsed mini-player is short enough to be obscured by the physical notch.
        // Keep it visibly below the notch while expanded panels still grow from the top edge.
        return 44
    }

    private func targetSize() -> CGSize {
        if store.isFirstRunSetupVisible {
            return setupSize
        }

        if store.isExpanded {
            return store.pinnedPlaylists.isEmpty ? expandedSize : expandedWithPlaylistsSize
        }

        return collapsedSize
    }

    private func notchSeedFrame(from frame: CGRect) -> CGRect {
        let width: CGFloat = 120
        let height: CGFloat = 34

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

    private func enableLaunchAtLogin() {
        do {
            try LaunchAtLoginController.setEnabled(true)
        } catch {
            NSSound.beep()
        }

        store.refreshSetupStatus()
    }

    private func screenForCurrentPointer() -> NSScreen {
        let pointer = NSEvent.mouseLocation
        return screen(containing: pointer)
    }

    private func activeScreen() -> NSScreen? {
        guard let activeScreenID else { return nil }
        return NSScreen.screens.first { screenID(for: $0) == activeScreenID }
    }

    private func activateScreenForCurrentPointer() {
        activeScreenID = screenID(for: screenForCurrentPointer())
    }

    private func activateScreen(containing point: CGPoint) {
        activeScreenID = screenID(for: screen(containing: point))
    }

    private func reconcileActiveScreen() {
        if let activeScreenID,
           NSScreen.screens.contains(where: { screenID(for: $0) == activeScreenID }) {
            return
        }

        if let manualPanelCenter {
            activateScreen(containing: manualPanelCenter)
        } else if panel.isVisible {
            activateScreen(containing: panel.frame.center)
        } else {
            activeScreenID = nil
        }
    }

    private func screen(containing point: CGPoint) -> NSScreen {
        NSScreen.screens.first { $0.frame.contains(point) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
            ?? NSScreen()
    }

    private func screenID(for screen: NSScreen) -> CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (screen.deviceDescription[key] as? NSNumber)?.uint32Value
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

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
