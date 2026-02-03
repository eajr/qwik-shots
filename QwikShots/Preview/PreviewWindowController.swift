import AppKit
import SwiftUI

private final class PreviewWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // escape
            performClose(nil)
        } else {
            super.keyDown(with: event)
        }
    }
}

final class PreviewWindowController: NSWindowController {
    private let viewModel = PreviewViewModel()

    init() {
        let window = PreviewWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "QwikShots"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        viewModel.onRequestClose = { [weak self] in
            self?.window?.performClose(nil)
        }

        let rootView = PreviewView(viewModel: viewModel)
        window.contentView = NSHostingView(rootView: rootView)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show(with image: NSImage) {
        viewModel.updateImage(image)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
