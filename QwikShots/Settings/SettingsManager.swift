import Foundation
import Combine

enum DefaultsKeys {
    // Existing
    static let lastSaveDirectory = "QwikShots.lastSaveDirectory"

    // Hotkey
    static let hotkeyKeyCode = "QwikShots.hotkey.keyCode"
    static let hotkeyModifiers = "QwikShots.hotkey.modifiers"

    // Default styles
    static let defaultPadding = "QwikShots.defaults.padding"
    static let defaultCornerRadius = "QwikShots.defaults.cornerRadius"
    static let defaultBackgroundID = "QwikShots.defaults.backgroundID"
    static let defaultShadowEnabled = "QwikShots.defaults.shadowEnabled"
    static let defaultShadowOpacity = "QwikShots.defaults.shadowOpacity"
    static let defaultShadowRadius = "QwikShots.defaults.shadowRadius"
    static let defaultShadowOffsetY = "QwikShots.defaults.shadowOffsetY"
}

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // Hotkey (stored as UInt32 values)
    @Published var hotkeyKeyCode: UInt32 {
        didSet {
            UserDefaults.standard.set(hotkeyKeyCode, forKey: DefaultsKeys.hotkeyKeyCode)
            hotkeyDidChange.send(keyCombo)
        }
    }
    @Published var hotkeyModifiers: UInt32 {
        didSet {
            UserDefaults.standard.set(hotkeyModifiers, forKey: DefaultsKeys.hotkeyModifiers)
            hotkeyDidChange.send(keyCombo)
        }
    }

    // Default styles
    @Published var defaultPadding: Double {
        didSet { UserDefaults.standard.set(defaultPadding, forKey: DefaultsKeys.defaultPadding) }
    }
    @Published var defaultCornerRadius: Double {
        didSet { UserDefaults.standard.set(defaultCornerRadius, forKey: DefaultsKeys.defaultCornerRadius) }
    }
    @Published var defaultBackgroundID: String {
        didSet { UserDefaults.standard.set(defaultBackgroundID, forKey: DefaultsKeys.defaultBackgroundID) }
    }
    @Published var defaultShadowEnabled: Bool {
        didSet { UserDefaults.standard.set(defaultShadowEnabled, forKey: DefaultsKeys.defaultShadowEnabled) }
    }
    @Published var defaultShadowOpacity: Double {
        didSet { UserDefaults.standard.set(defaultShadowOpacity, forKey: DefaultsKeys.defaultShadowOpacity) }
    }
    @Published var defaultShadowRadius: Double {
        didSet { UserDefaults.standard.set(defaultShadowRadius, forKey: DefaultsKeys.defaultShadowRadius) }
    }
    @Published var defaultShadowOffsetY: Double {
        didSet { UserDefaults.standard.set(defaultShadowOffsetY, forKey: DefaultsKeys.defaultShadowOffsetY) }
    }

    // Publisher for hotkey changes (AppDelegate subscribes to this)
    let hotkeyDidChange = PassthroughSubject<KeyCombo, Never>()

    var keyCombo: KeyCombo {
        KeyCombo(keyCode: hotkeyKeyCode, modifiers: hotkeyModifiers)
    }

    private init() {
        let defaults = UserDefaults.standard

        // Load hotkey (with defaults matching KeyCombo.commandShift9)
        let storedKeyCode = defaults.object(forKey: DefaultsKeys.hotkeyKeyCode) as? UInt32
        let storedModifiers = defaults.object(forKey: DefaultsKeys.hotkeyModifiers) as? UInt32

        if let keyCode = storedKeyCode, let modifiers = storedModifiers {
            self.hotkeyKeyCode = keyCode
            self.hotkeyModifiers = modifiers
        } else {
            // Use default hotkey
            let defaultCombo = KeyCombo.commandShift9
            self.hotkeyKeyCode = defaultCombo.keyCode
            self.hotkeyModifiers = defaultCombo.modifiers
        }

        // Load style defaults (with hardcoded fallbacks)
        self.defaultPadding = defaults.object(forKey: DefaultsKeys.defaultPadding) as? Double ?? 50
        self.defaultCornerRadius = defaults.object(forKey: DefaultsKeys.defaultCornerRadius) as? Double ?? 16
        self.defaultBackgroundID = defaults.string(forKey: DefaultsKeys.defaultBackgroundID) ?? BackgroundCatalog.defaultBackgroundID
        self.defaultShadowEnabled = defaults.object(forKey: DefaultsKeys.defaultShadowEnabled) as? Bool ?? true
        self.defaultShadowOpacity = defaults.object(forKey: DefaultsKeys.defaultShadowOpacity) as? Double ?? 0.25
        self.defaultShadowRadius = defaults.object(forKey: DefaultsKeys.defaultShadowRadius) as? Double ?? 18
        self.defaultShadowOffsetY = defaults.object(forKey: DefaultsKeys.defaultShadowOffsetY) as? Double ?? 0
    }

    func updateHotkey(_ combo: KeyCombo) {
        hotkeyKeyCode = combo.keyCode
        hotkeyModifiers = combo.modifiers
    }
}
