import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let captureCoordinator = CaptureCoordinator()
    private var hotKeyManager: HotKeyManager?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize with saved hotkey from SettingsManager
        let initialCombo = SettingsManager.shared.keyCombo
        hotKeyManager = HotKeyManager(keyCombo: initialCombo) { [weak self] in
            self?.startCapture()
        }

        // Subscribe to hotkey changes from settings
        SettingsManager.shared.hotkeyDidChange
            .sink { [weak self] newCombo in
                self?.hotKeyManager?.updateHotKey(newCombo)
            }
            .store(in: &cancellables)
    }

    func startCaptureFromMenu() {
        startCapture()
    }

    func showSettings() {
        SettingsWindowController.shared.showSettings()
    }

    private func startCapture() {
        captureCoordinator.beginCapture()
    }
}
