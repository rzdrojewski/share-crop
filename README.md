# ScreenShare

`ScreenShare` is a macOS app that lets you pick a region of a display, mirror that crop live, and expose a dedicated `Share Crop` window that can be shared in tools like Microsoft Teams, Zoom, and Slack.

## What It Does

- Requests macOS screen recording permission.
- Lets the user choose a display.
- Captures a still image of that display for crop selection.
- Starts a live cropped capture loop for the selected region.
- Shows the cropped output in:
  - the main app window for local preview
  - a separate `Share Crop` window intended for conferencing apps

## Project Layout

- `App/`
  App entry point and app lifecycle.
- `Models/`
  Small value types such as displays, capture regions, and selection drafts.
- `Services/`
  App state, capture loop, and share-window management.
- `Support/`
  Environment flags and smoke-test helpers.
- `Views/`
  SwiftUI surfaces for setup, region selection, and preview.
- `script/`
  Local build/run and smoke-test scripts.
- `docs/`
  Architecture and implementation notes.

## Run Locally

Build from the project root:

```bash
swift build
```

Run through the bundled script:

```bash
./script/build_and_run.sh
```

Verify the packaged app launches:

```bash
./script/build_and_run.sh --verify
```

Run the repo CI checks locally:

```bash
./script/ci.sh
```

## How To Use

1. Launch the app.
2. Grant screen recording access if macOS prompts for it.
3. Pick a display.
4. Click `Choose Region`.
5. Drag a crop over the still display preview and confirm it.
6. Click `Start Capture`.
7. Share the `Share Crop` window in Teams, Zoom, or Slack.

## Smoke Test

There is a built-in smoke-test mode for validating the app without depending on real display content:

```bash
./script/smoke_test.sh
```

This mode uses synthetic display content and writes a captured frame to `dist/smoke-frame.png` when successful.

## CI And Releases

GitHub Actions now provides:

- pull request and `main` branch CI on `macos-latest`
- tag-triggered unsigned GitHub Releases for tags matching `vX.Y.Z`
- auto-generated GitHub Release notes

Build the unsigned release DMG locally with:

```bash
./script/package_release.sh --version 0.1.0 --artifact-version v0.1.0
```

Phase 1 release artifacts are intentionally unsigned. They are suitable for the current free setup, but users should expect macOS Gatekeeper warnings until `Developer ID` signing and notarization are added later.

Release workflow details live in [docs/releasing.md](./docs/releasing.md).

## Current Constraints

- The capture loop currently uses repeated display snapshots rather than `ScreenCaptureKit` streaming.
- Real-world conferencing-app compatibility depends on whether they list the `Share Crop` window as a normal shareable macOS window.
- The smoke test validates the app-controlled pipeline, but it does not prove macOS TCC prompts or conferencing-app integration.

## Architecture

High-level architecture notes live in [docs/architecture.md](./docs/architecture.md).
