# QwikShots

Menu‑bar screenshot tool for macOS. Press `⌘⇧9`, drag to select, then edit with backdrops, padding, rounded corners, and shadow. Save to a file or copy to clipboard.

## Requirements

- macOS 14+ (Sonoma or newer)
- Xcode 15+ (SwiftUI)

## Run

1. Open `QwikShots.xcodeproj` in Xcode.
2. Select the `QwikShots` scheme and Run.
3. On first capture, macOS will prompt for Screen Recording permission.
   - If you miss the prompt: System Settings → Privacy & Security → Screen Recording → enable QwikShots.

## Usage

- Click the menu‑bar icon → **Capture (⌘⇧9)**, or press `⌘⇧9` directly.
- Drag to select a region on the current monitor.
- Adjust background, padding, corner radius, and shadow in the preview window.
- **Copy** copies the edited image to clipboard and closes the preview.
- **Save…** lets you choose a destination and remembers the last folder.

## Notes

- The app is a menu‑bar‑only agent (`LSUIElement = true`), so it won’t appear in the Dock.
- `⌘⇧9` is registered globally; if another app or system shortcut uses it, disable that shortcut in System Settings → Keyboard → Keyboard Shortcuts.
