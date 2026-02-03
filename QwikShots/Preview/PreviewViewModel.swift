import AppKit

final class PreviewViewModel: ObservableObject {
    @Published var availableBackgrounds: [BackgroundOption] = BackgroundCatalog.load()
    @Published var selectedBackgroundID: String = BackgroundCatalog.defaultBackgroundID

    @Published var padding: Double = 50 { didSet { rebuildRenderedImage() } }
    @Published var cornerRadius: Double = 16 { didSet { rebuildRenderedImage() } }
    @Published var shadowEnabled: Bool = true { didSet { rebuildRenderedImage() } }
    @Published var shadowOpacity: Double = 0.25 { didSet { rebuildRenderedImage() } }
    @Published var shadowRadius: Double = 18 { didSet { rebuildRenderedImage() } }
    @Published var shadowOffsetY: Double = 0 { didSet { rebuildRenderedImage() } }

    @Published private(set) var renderedImage: NSImage = NSImage(size: .zero)

    var onRequestClose: (() -> Void)?

    private var originalImage: NSImage?
    private var renderSequence: Int = 0
    private var renderWorkItem: DispatchWorkItem?

    init() {
        if let first = availableBackgrounds.first {
            selectedBackgroundID = first.id
        }
    }

    func updateImage(_ image: NSImage) {
        originalImage = image
        rebuildRenderedImage()
    }

    func rebuildRenderedImage() {
        guard let originalImage else { return }

        let background = availableBackgrounds.first { $0.id == selectedBackgroundID } ?? BackgroundCatalog.fallbackBackground
        let shadow = ShadowOptions(
            enabled: shadowEnabled,
            opacity: shadowOpacity,
            blurRadius: CGFloat(shadowRadius),
            offsetY: CGFloat(shadowOffsetY)
        )
        let padding = CGFloat(padding)
        let cornerRadius = CGFloat(cornerRadius)

        renderSequence += 1
        let sequence = renderSequence

        renderWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            let image = ImageRenderer.render(
                original: originalImage,
                background: background,
                padding: padding,
                cornerRadius: cornerRadius,
                shadow: shadow
            )
            DispatchQueue.main.async {
                guard let self, self.renderSequence == sequence else { return }
                self.renderedImage = image
            }
        }

        renderWorkItem = workItem
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.03, execute: workItem)
    }

    func copyToClipboard() {
        guard let image = renderImageNow() else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        onRequestClose?()
    }

    func saveToFile() {
        guard let image = renderImageNow(), let pngData = image.pngData else { return }

        let panel = NSSavePanel()
        panel.allowedFileTypes = ["png"]
        panel.nameFieldStringValue = "QwikShots.png"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        if let lastDir = UserDefaults.standard.url(forKey: DefaultsKeys.lastSaveDirectory) {
            panel.directoryURL = lastDir
        }

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try pngData.write(to: url, options: .atomic)
                UserDefaults.standard.set(url.deletingLastPathComponent(), forKey: DefaultsKeys.lastSaveDirectory)
                self?.onRequestClose?()
            } catch {
                NSSound.beep()
            }
        }
    }

    private func renderImageNow() -> NSImage? {
        guard let originalImage else { return nil }

        let background = availableBackgrounds.first { $0.id == selectedBackgroundID } ?? BackgroundCatalog.fallbackBackground
        let shadow = ShadowOptions(
            enabled: shadowEnabled,
            opacity: shadowOpacity,
            blurRadius: CGFloat(shadowRadius),
            offsetY: CGFloat(shadowOffsetY)
        )

        let image = ImageRenderer.render(
            original: originalImage,
            background: background,
            padding: CGFloat(padding),
            cornerRadius: CGFloat(cornerRadius),
            shadow: shadow
        )
        renderedImage = image
        return image
    }
}

enum DefaultsKeys {
    static let lastSaveDirectory = "QwikShots.lastSaveDirectory"
}

struct ShadowOptions {
    let enabled: Bool
    let opacity: Double
    let blurRadius: CGFloat
    let offsetY: CGFloat
}
