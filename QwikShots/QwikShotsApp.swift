import SwiftUI

@main
struct QwikShotsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("QwikShots", systemImage: "camera") {
            Button("Capture Area") {
                appDelegate.startCaptureFromMenu()
            }
            .keyboardShortcut("9", modifiers: [.command, .shift])

            Button("Settings...") {
                // TODO: Open settings window
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Exit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .menuBarExtraStyle(.menu)
    }
}
