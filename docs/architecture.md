# Architecture

## Overview

The app is organized around a simple pipeline:

1. Detect displays and request screen recording access.
2. Snapshot the selected display.
3. Let the user choose a crop against that snapshot.
4. Start a recurring capture loop for the chosen crop.
5. Publish frames to both:
   - the in-app preview
   - the dedicated `Share Crop` window

The current implementation prioritizes stability and debuggability over maximum efficiency.

## Main Components

### `App/ScreenShareApp.swift`

- Defines the app entry point.
- Creates the main SwiftUI window.
- Installs a standard foreground macOS app activation policy.

### `Services/AppModel.swift`

`AppModel` is the main coordinator for user actions and app state.

Responsibilities:

- track available displays
- track permission state
- manage the current crop selection
- prepare the selection draft image
- start and stop live capture
- open the dedicated share window
- drive smoke-test bootstrapping

`AppModel` is intentionally the main state owner so the rest of the code stays narrow and easier to reason about.

### `Services/ScreenRecorder.swift`

`ScreenRecorder` owns the live capture loop.

Current behavior:

- creates a `DispatchSourceTimer` on `ScreenShare.capture-output`
- periodically snapshots the source display
- crops the snapshot into the selected region
- posts finished frames back to the main thread
- updates observable preview state

This service is `@MainActor` for published UI state, but its actual capture work is kept in static nonisolated helpers so the background queue does not inherit main-actor isolation.

### `Services/SharePreviewWindowController.swift`

This controller owns the dedicated shareable output window.

Design choice:

- It uses plain AppKit controls (`NSWindow`, `NSImageView`, `NSTextField`) instead of a SwiftUI-hosted window.

Reason:

- Earlier iterations using a SwiftUI-hosted preview window were materially less stable during capture startup.
- A plain AppKit preview window is simpler, more isolated, and a better fit for a conferencing-app share target.

### `Views/ContentView.swift`

This is the main app surface.

It combines:

- display selection
- permission status
- crop initiation
- capture controls
- live in-app preview

### `Views/SelectionEditorView.swift`

This view handles region selection entirely inside the main window.

Reason:

- Earlier full-screen overlay approaches introduced AppKit lifecycle instability.
- An in-window crop editor is easier to debug and avoids transient overlay-window teardown issues.

### `Support/AppEnvironment.swift`

Defines process-level flags, currently used for smoke-test behavior.

### `Support/MockCaptureFactory.swift`

Creates deterministic synthetic display content used by the smoke test.

## Data Flow

### Region Selection

1. `AppModel.chooseRegion()` snapshots the chosen display.
2. The snapshot becomes a `SelectionDraft`.
3. `SelectionEditorView` lets the user drag a crop.
4. `AppModel.confirmSelection(_:)` turns the result into a `CaptureRegion`.

### Live Capture

1. `AppModel.startSharing()` validates the chosen display and crop.
2. `ScreenRecorder.startCapture(...)` starts the timer.
3. Each timer tick captures a display image, crops it, and posts a frame-ready notification.
4. `ScreenRecorder` updates `latestFrame`.
5. SwiftUI preview surfaces and the AppKit share window consume the same image stream.

## Why Not `ScreenCaptureKit` Streaming

The codebase intentionally moved away from `SCShareableContent`/`SCStream` in the initial version.

Reason:

- earlier iterations hit repeated crashes during selection and stream setup
- the narrower snapshot-based pipeline was easier to stabilize
- the product goal for an initial version is “works reliably enough to share a crop window,” not “perfectly optimized streaming architecture”

This is a tradeoff, not a permanent architecture claim.

## Testing Strategy

### Manual

Manual testing still matters for:

- macOS screen recording permission prompts
- actual display contents
- Teams/Zoom/Slack window-share detection

### Automated

The smoke-test path exists to reduce repeated manual verification.

It does the following:

- switches display enumeration to a synthetic display
- skips real display capture dependency
- bootstraps a default crop
- starts the capture loop
- verifies that a frame can be written to disk

Entry point:

```bash
./script/smoke_test.sh
```

## Known Risks

- Snapshot-based capture is less efficient than a proper stream.
- The share window may still need tuning for how conferencing apps enumerate shareable windows.
- The current architecture is optimized for a stable initial version, not yet for packaging, signing, or long-session performance.

## Next Likely Refactors

- replace the timer snapshot loop with a stable stream-based capture backend
- add explicit telemetry around frame timing and capture failures
- separate product state from smoke-test wiring more cleanly
- add a stronger automated assertion around share-window readiness
