import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let captureCoordinator = CaptureCoordinator()
    private var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotKeyManager = HotKeyManager(keyCombo: .commandShift9) { [weak self] in
            self?.startCapture()
        }
    }

    func startCaptureFromMenu() {
        startCapture()
    }

    private func startCapture() {
        captureCoordinator.beginCapture()
    }
}
