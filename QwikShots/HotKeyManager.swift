import AppKit
import Carbon.HIToolbox

struct KeyCombo: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    static let commandShift9 = KeyCombo(
        keyCode: UInt32(kVK_ANSI_9),
        modifiers: UInt32(cmdKey | shiftKey)
    )
}

final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let handler: () -> Void

    init(keyCombo: KeyCombo, handler: @escaping () -> Void) {
        self.handler = handler
        registerHotKey(keyCombo)
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    func updateHotKey(_ combo: KeyCombo) {
        // Unregister existing hotkey
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        // Register new hotkey
        var hotKeyID = EventHotKeyID(
            signature: "QSHK".fourCharCode,
            id: 1
        )

        RegisterEventHotKey(
            combo.keyCode,
            combo.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func registerHotKey(_ combo: KeyCombo) {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handler()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )

        // Use updateHotKey to register the initial hotkey
        updateHotKey(combo)
    }
}

private extension String {
    var fourCharCode: OSType {
        var result: OSType = 0
        for scalar in unicodeScalars {
            result = (result << 8) + OSType(scalar.value)
        }
        return result
    }
}
