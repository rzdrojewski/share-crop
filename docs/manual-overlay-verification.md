# Manual Overlay Verification

This checklist records the remaining manual verification work for the overlay-selection feature. It has not been executed automatically.

## Overlay Presentation

- Launch the app and choose a display.
- Trigger `Choose Region` and confirm the overlay appears only on the selected display.
- Confirm the rest of the selected display is dimmed and the active selection area remains visually clear.
- Confirm the resize handles are visible and remain aligned with the selection bounds.

## Keyboard And Focus

- Verify the overlay becomes key immediately after opening.
- Press `Esc` and confirm the overlay closes without overwriting an existing saved region.
- Reopen the overlay, create a valid region, press `Enter`, and confirm the overlay closes with the new selection saved.
- Attempt to confirm an undersized region and verify the confirm button remains disabled.

## End-To-End Selection Flow

- Complete a first-time region selection, open `Share Crop`, start capture, and verify the preview updates.
- Retake the region with capture stopped, confirm a new selection, and verify the share window uses the new crop.
- Start capture, retake the region while sharing is active, confirm the new region, and verify capture resumes with the updated crop.
- Start capture, retake the region while sharing is active, cancel, and verify capture resumes with the prior crop.

## Notes

- Record any focus, overlay-lifecycle, or share-window issues discovered during the checks above before closing Phase 5.
