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
            frozenImage: frozenImage,
            onSelection: onSelection
        )

        contentView = selectionView
        makeFirstResponder(selectionView)
    }
}

final class SelectionOverlayView: NSView {
    private let frozenImage: NSImage?
    private let onSelection: (NSImage?) -> Void
    private var startPoint: NSPoint?
    private var selectionRect: NSRect?

    init(frame: NSRect, frozenImage: NSImage?, onSelection: @escaping (NSImage?) -> Void) {
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
        let point = convert(event.locationInWindow, from: nil)
        startPoint = point
        selectionRect = NSRect(origin: point, size: .zero)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startPoint else { return }
        let currentPoint = convert(event.locationInWindow, from: nil)
        let rect = SelectionOverlayView.rect(from: startPoint, to: currentPoint)
        selectionRect = rect.intersection(bounds)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let selectionRect else {
            onSelection(nil)
            return
        }

        if selectionRect.width < 2 || selectionRect.height < 2 {
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

        // Scale from view coordinates (points) to CGImage coordinates (pixels)
        let scaleX = CGFloat(cgImage.width) / viewSize.width
        let scaleY = CGFloat(cgImage.height) / viewSize.height

        // Simple scaling - NO FLIP needed
        // Both isFlipped NSView and CGImage use top-left origin with Y increasing downward
        let cropRect = CGRect(
            x: floor(rectInView.origin.x * scaleX),
            y: floor(rectInView.origin.y * scaleY),
            width: ceil(rectInView.size.width * scaleX),
            height: ceil(rectInView.size.height * scaleY)
        )

        let imageBounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let finalRect = cropRect.intersection(imageBounds)
        guard !finalRect.isEmpty, let cropped = cgImage.cropping(to: finalRect) else {
            return nil
        }

        return NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
    }
}
