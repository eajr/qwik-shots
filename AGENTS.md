# QwikShots – Developer Notes

## Overview
QwikShots is a native macOS **menu‑bar** screenshot tool built with Swift/SwiftUI. It registers a global hotkey (`⌘⇧9`), shows a full‑screen selection overlay on the current monitor, captures the selected region, then opens a resizable preview/editor window to apply background, padding, rounded corners, and shadow. Output can be copied to clipboard or saved as a PNG.

## Project Structure

- `QwikShots.xcodeproj/`
  - Xcode project file.
- `QwikShots/`
  - `QwikShotsApp.swift`: SwiftUI entry point; menu‑bar extra UI.
  - `AppDelegate.swift`: app lifecycle + hotkey wiring.
  - `HotKeyManager.swift`: Carbon hotkey registration.
  - `CaptureCoordinator.swift`: orchestrates capture flow and preview window.
  - `SelectionOverlayWindow.swift`: full‑screen overlay, selection UI, and crop logic.
  - `Preview/`
    - `PreviewWindowController.swift`: host window for SwiftUI preview UI.
    - `PreviewView.swift`: UI controls + preview image.
    - `PreviewViewModel.swift`: state management, rendering, save/copy actions.
    - `BackgroundCatalog.swift`: built‑in gradients + bundled image discovery.
    - `ImageRenderer.swift`: CoreGraphics compositor (background + rounded image + shadow).
  - `Resources/`
    - `Backgrounds/`: optional bundled background images.
- `scripts/`
  - `fetch_backgrounds.sh`: downloads CC0 background assets (Wikimedia Commons).
- `LICENSES.md`
  - attribution for optional backgrounds.
- `README.md`
  - setup + usage.

## Build & Run

CLI build:

```bash
xcodebuild -project QwikShots.xcodeproj \
  -scheme QwikShots \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  build
```

Run:

```bash
open build/Build/Products/Debug/QwikShots.app
```

> Requires Xcode installed (for SDK/toolchain).

## Permissions

Screen capture requires **Screen Recording** permission.
If capture shows only wallpaper, re‑enable in:
`System Settings → Privacy & Security → Screen Recording`.

## Hotkey

Global hotkey is registered in `HotKeyManager` (`⌘⇧9`).
If it conflicts with other shortcuts, change in code and/or disable the system shortcut.

## Capture Pipeline

1. `CaptureCoordinator.beginCapture()` chooses the screen under the mouse.
2. A full‑screen frozen image is captured for that display.
3. `SelectionOverlayWindow` shows overlay and tracks drag selection.
4. Selected region is cropped directly from the frozen image (avoids coordinate drift).
5. The cropped image is passed to `PreviewWindowController`.

## Image Rendering

`ImageRenderer` builds the final output using CoreGraphics:
- background (solid/gradient/image)
- rounded original image
- optional drop shadow
- padding around the content

Rendering is throttled/debounced in `PreviewViewModel` to prevent UI stalls.

## Background Assets

- Built‑in gradients + solid colors defined in `BackgroundCatalog`.
- Optional image backgrounds loaded from `QwikShots/Resources/Backgrounds` at runtime.
- Run `scripts/fetch_backgrounds.sh` to download CC0 images (documented in `LICENSES.md`).

## Notes / Known Limitations

- `CGWindowListCreateImage` is used for screen capture (deprecated in macOS 14). Future work: migrate to ScreenCaptureKit.
- Menu‑bar only app (`LSUIElement = true` in `Info.plist`).
- Capture alignment has a small display‑specific adjustment (menu‑bar height); if capture is off, check the adjustment in `SelectionOverlayWindow.swift`.

## Conventions

- Swift 5.10, macOS 14+ target.
- Use CoreGraphics for rendering to avoid SwiftUI image scaling artifacts.
- Avoid long‑running work on main thread; rendering uses background queues.
