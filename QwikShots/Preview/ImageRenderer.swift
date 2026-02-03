import AppKit

enum ImageRenderer {
    static func render(
        original: NSImage,
        background: BackgroundOption,
        padding: CGFloat,
        cornerRadius: CGFloat,
        shadow: ShadowOptions
    ) -> NSImage {
        guard let originalCG = original.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return original
        }

        let originalSize = CGSize(width: originalCG.width, height: originalCG.height)
        let canvasSize = CGSize(
            width: originalSize.width + padding * 2,
            height: originalSize.height + padding * 2
        )

        guard let context = CGContext(
            data: nil,
            width: Int(canvasSize.width),
            height: Int(canvasSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return original
        }

        context.interpolationQuality = .high

        // Flip into a top-left origin coordinate system.
        context.translateBy(x: 0, y: canvasSize.height)
        context.scaleBy(x: 1, y: -1)

        let backgroundRect = CGRect(origin: .zero, size: canvasSize)
        drawBackground(background, in: backgroundRect, context: context)

        let contentRect = CGRect(
            x: padding,
            y: padding,
            width: originalSize.width,
            height: originalSize.height
        )

        let roundedRadius = max(0, min(cornerRadius, min(originalSize.width, originalSize.height) / 2))
        guard let roundedImage = renderRoundedImage(
            originalCG: originalCG,
            size: originalSize,
            cornerRadius: roundedRadius
        ) else {
            return original
        }

        if shadow.enabled {
            let shadowColor = NSColor.black.withAlphaComponent(shadow.opacity).cgColor
            context.setShadow(offset: CGSize(width: 0, height: -shadow.offsetY), blur: shadow.blurRadius, color: shadowColor)
        } else {
            context.setShadow(offset: .zero, blur: 0, color: nil)
        }

        context.draw(roundedImage, in: contentRect)

        guard let output = context.makeImage() else { return original }
        return NSImage(cgImage: output, size: canvasSize)
    }

    private static func drawBackground(_ background: BackgroundOption, in rect: CGRect, context: CGContext) {
        switch background.kind {
        case .solid(let color):
            context.setFillColor(color.toCGColor())
            context.fill(rect)

        case .gradient(let colors):
            let cgColors = colors.map { $0.toCGColor() }
            let fallback = [NSColor.white.toCGColor(), NSColor.black.toCGColor()]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: (cgColors.isEmpty ? fallback : cgColors) as CFArray,
                locations: nil
            )
            if let gradient {
                let start = CGPoint(x: rect.midX, y: rect.minY)
                let end = CGPoint(x: rect.midX, y: rect.maxY)
                context.drawLinearGradient(gradient, start: start, end: end, options: [])
            } else {
                context.setFillColor(NSColor.darkGray.cgColor)
                context.fill(rect)
            }

        case .image(let url):
            guard let image = NSImage(contentsOf: url),
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
            else {
                context.setFillColor(NSColor.darkGray.cgColor)
                context.fill(rect)
                return
            }
            let drawRect = aspectFillRect(for: CGSize(width: cgImage.width, height: cgImage.height), in: rect)
            context.draw(cgImage, in: drawRect)
        }
    }

    private static func renderRoundedImage(
        originalCG: CGImage,
        size: CGSize,
        cornerRadius: CGFloat
    ) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)

        let rect = CGRect(origin: .zero, size: size)
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        context.addPath(path)
        context.clip()
        context.draw(originalCG, in: rect)
        return context.makeImage()
    }

    private static func aspectFillRect(for imageSize: CGSize, in targetRect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return targetRect }

        let widthRatio = targetRect.width / imageSize.width
        let heightRatio = targetRect.height / imageSize.height
        let scale = max(widthRatio, heightRatio)

        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: targetRect.midX - scaledSize.width / 2,
            y: targetRect.midY - scaledSize.height / 2
        )

        return CGRect(origin: origin, size: scaledSize)
    }
}

extension NSImage {
    var pixelSize: CGSize {
        guard let representation = representations.first else { return size }
        return CGSize(width: representation.pixelsWide, height: representation.pixelsHigh)
    }

    var pngData: Data? {
        guard let representation = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: representation)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}

private extension NSColor {
    func toCGColor() -> CGColor {
        (usingColorSpace(.deviceRGB) ?? self).cgColor
    }
}
