import SwiftUI

@main
struct QwikShotsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("QwikShots", systemImage: "camera") {
            Button("Capture (⌘⇧9)") {
                appDelegate.startCaptureFromMenu()
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
