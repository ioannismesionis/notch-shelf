import Carbon.HIToolbox
import Foundation

final class KeyboardShortcutController {
    static let shared = KeyboardShortcutController()

    var onHotKey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private(set) var lastError: OSStatus = noErr

    private static let signature = fourCharCode("NTSH")
    private static let hotKeyID = UInt32(1)

    private init() {}

    deinit {
        unregister()
    }

    func setEnabled(_ isEnabled: Bool) {
        isEnabled ? register() : unregister()
    }

    private func register() {
        guard hotKeyRef == nil else { return }

        installEventHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: Self.hotKeyID)
        var hotKeyRef: EventHotKeyRef?
        lastError = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if lastError == noErr {
            self.hotKeyRef = hotKeyRef
        }
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                guard let event else { return noErr }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr,
                      hotKeyID.signature == KeyboardShortcutController.signature,
                      hotKeyID.id == KeyboardShortcutController.hotKeyID else {
                    return noErr
                }

                DispatchQueue.main.async {
                    KeyboardShortcutController.shared.onHotKey?()
                }

                return noErr
            },
            1,
            &eventSpec,
            nil,
            &eventHandlerRef
        )
    }
}

private func fourCharCode(_ string: String) -> OSType {
    string.utf8.reduce(0) { result, character in
        (result << 8) + OSType(character)
    }
}
