import AppKit

final class CaptureCoordinator: NSObject {
    private var overlayWindow: SelectionOverlayWindow?
    private var previewWindowController: PreviewWindowController?

    func beginCapture() {
        guard let screen = Self.screenForCurrentMouse() else {
            NSSound.beep()
            return
        }

        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
        }

        let frozenImage = ScreenCapture.captureScreenImage(for: screen)
        let overlay = SelectionOverlayWindow(screen: screen, frozenImage: frozenImage) { [weak self] selectionImage in
            guard let self else { return }
            self.overlayWindow?.orderOut(nil)
            self.overlayWindow = nil

            guard let selectionImage else { return }
            self.showPreview(with: selectionImage)
        }

        overlayWindow = overlay
        overlay.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // Cropping is handled directly from the frozen image in SelectionOverlayView.

    private func showPreview(with image: NSImage) {
        // Create a new controller each time to pick up current default settings
        previewWindowController = PreviewWindowController()
        previewWindowController?.show(with: image)
    }

    private static func screenForCurrentMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main
    }
}

enum ScreenCapture {
    static func captureScreenImage(for screen: NSScreen) -> NSImage? {
        guard let displayID = screen.displayID else { return nil }
        let rect = CGDisplayBounds(displayID)
        guard let cgImage = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution]) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return nil }
        return CGDirectDisplayID(number.uint32Value)
    }
}
