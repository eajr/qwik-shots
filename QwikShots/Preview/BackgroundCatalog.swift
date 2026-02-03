import AppKit

struct BackgroundOption: Identifiable, Hashable {
    enum Kind: Hashable {
        case solid(NSColor)
        case gradient([NSColor])
        case image(URL)
    }

    let id: String
    let name: String
    let kind: Kind
}

enum BackgroundCatalog {
    static let defaultBackgroundID = "gradient-sunset"

    static var fallbackBackground: BackgroundOption {
        BackgroundOption(
            id: "solid-white",
            name: "White",
            kind: .solid(.white)
        )
    }

    static func load() -> [BackgroundOption] {
        var options: [BackgroundOption] = [
            BackgroundOption(
                id: "gradient-sunset",
                name: "Sunset",
                kind: .gradient([
                    NSColor(calibratedRed: 0.98, green: 0.62, blue: 0.45, alpha: 1),
                    NSColor(calibratedRed: 0.74, green: 0.35, blue: 0.85, alpha: 1)
                ])
            ),
            BackgroundOption(
                id: "gradient-ocean",
                name: "Ocean",
                kind: .gradient([
                    NSColor(calibratedRed: 0.28, green: 0.65, blue: 0.96, alpha: 1),
                    NSColor(calibratedRed: 0.12, green: 0.24, blue: 0.62, alpha: 1)
                ])
            ),
            BackgroundOption(
                id: "gradient-forest",
                name: "Forest",
                kind: .gradient([
                    NSColor(calibratedRed: 0.29, green: 0.80, blue: 0.62, alpha: 1),
                    NSColor(calibratedRed: 0.16, green: 0.40, blue: 0.35, alpha: 1)
                ])
            ),
            BackgroundOption(
                id: "solid-white",
                name: "White",
                kind: .solid(.white)
            ),
            BackgroundOption(
                id: "solid-black",
                name: "Black",
                kind: .solid(.black)
            )
        ]

        if let resourceURLs = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "Backgrounds") {
            for url in resourceURLs {
                let ext = url.pathExtension.lowercased()
                guard ["jpg", "jpeg", "png", "heic"].contains(ext) else { continue }
                let name = url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "-", with: " ")
                options.append(
                    BackgroundOption(
                        id: "asset-\(url.lastPathComponent)",
                        name: name.capitalized,
                        kind: .image(url)
                    )
                )
            }
        }

        return options
    }
}
