import AppKit

final class SelectionOverlayWindow: NSWindow {
    init(screen: NSScreen, frozenImage: NSImage?, onSelection: @escaping (NSImage?) -> Void) {
        let contentRect = screen.frame
        let styleMask: NSWindow.StyleMask = [.borderless]
        super.init(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        setFrame(contentRect, display: false)

        isOpaque = true
        backgroundColor = .clear
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hasShadow = false
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        isMovable = false

        let selectionView = SelectionOverlayView(
            frame: NSRect(origin: .zero, size: contentRect.size),
            screen: screen,
            frozenImage: frozenImage,
            onSelection: onSelection
        )

        contentView = selectionView
        makeFirstResponder(selectionView)
    }
}

final class SelectionOverlayView: NSView {
    private let screen: NSScreen
    private let frozenImage: NSImage?
    private let onSelection: (NSImage?) -> Void
    private var startPointWindow: NSPoint?
    private var selectionRectWindow: NSRect?
    private var selectionRect: NSRect?

    init(frame: NSRect, screen: NSScreen, frozenImage: NSImage?, onSelection: @escaping (NSImage?) -> Void) {
        self.screen = screen
        self.frozenImage = frozenImage
        self.onSelection = onSelection
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    override func mouseDown(with event: NSEvent) {
        startPointWindow = event.locationInWindow
        selectionRectWindow = NSRect(origin: startPointWindow ?? .zero, size: .zero)
        selectionRect = selectionRectWindow.map { convert($0, from: nil) }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startPointWindow else { return }
        let currentWindow = event.locationInWindow
        let windowRect = SelectionOverlayView.rect(from: startPointWindow, to: currentWindow)
        selectionRectWindow = windowRect
        selectionRect = convert(windowRect, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let selectionRectWindow else {
            onSelection(nil)
            return
        }

        if selectionRectWindow.width < 2 || selectionRectWindow.height < 2 {
            onSelection(nil)
            return
        }

        guard let selectionRect else {
            onSelection(nil)
            return
        }

        onSelection(cropFrozenImage(for: selectionRect))
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // escape
            onSelection(nil)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        if let frozenImage {
            frozenImage.draw(in: bounds)
        } else {
            NSColor.black.setFill()
            bounds.fill()
        }

        let overlayPath = NSBezierPath(rect: bounds)
        if let selectionRect {
            overlayPath.append(NSBezierPath(rect: selectionRect))
            overlayPath.windingRule = .evenOdd
        }
        NSColor.black.withAlphaComponent(0.35).setFill()
        overlayPath.fill()

        if let selectionRect {
            NSColor.white.setStroke()
            let outline = NSBezierPath(rect: selectionRect)
            outline.lineWidth = 1
            outline.stroke()
        }
    }

    private static func rect(from start: NSPoint, to end: NSPoint) -> NSRect {
        let origin = NSPoint(x: min(start.x, end.x), y: min(start.y, end.y))
        let size = NSSize(width: abs(start.x - end.x), height: abs(start.y - end.y))
        return NSRect(origin: origin, size: size)
    }

    private func cropFrozenImage(for rectInView: CGRect) -> NSImage? {
        guard let frozenImage,
              let cgImage = frozenImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }

        let viewSize = bounds.size
        guard viewSize.width > 0, viewSize.height > 0 else { return nil }

        let scaleX = CGFloat(cgImage.width) / viewSize.width
        let scaleY = CGFloat(cgImage.height) / viewSize.height

        let menuBarHeight = max(0, screen.frame.maxY - screen.visibleFrame.maxY)
        let menuBarAdjustment = menuBarHeight * 0.4
        let maxY = max(0, viewSize.height - rectInView.size.height)
        let yTopAdjusted = min(maxY, rectInView.origin.y + menuBarAdjustment)

        let x = rectInView.origin.x * scaleX
        let yTop = yTopAdjusted * scaleY
        let width = rectInView.size.width * scaleX
        let height = rectInView.size.height * scaleY

        let y = CGFloat(cgImage.height) - (yTop + height)

        let cropRect = CGRect(
            x: x.rounded(.down),
            y: y.rounded(.down),
            width: width.rounded(.up),
            height: height.rounded(.up)
        )

        let imageBounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let finalRect = cropRect.intersection(imageBounds)
        guard !finalRect.isEmpty, let cropped = cgImage.cropping(to: finalRect) else {
            return nil
        }

        return NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
    }
}
