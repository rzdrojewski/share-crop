## Problem Statement

The app currently asks the user to define the shared area by dragging over a still screenshot shown inside the main app window. This works, but it adds friction because the user is not selecting directly on the screen they intend to share. The user wants to select the zone directly on a translucent overlay placed on top of the chosen display so the interaction feels closer to native screen capture tools and gives a more polished setup flow.

## Solution

Replace the in-window screenshot crop flow with a display-local overlay selection flow. When the user chooses or retakes a region, the app will open a translucent overlay on the selected display only. The overlay will dim the screen, show the current crop if one exists, and let the user drag to create, move, and resize the selection using visible handles on the corners and midpoints of each edge. The user will confirm with `Enter` and cancel with `Esc`. For the first version, the overlay remains visually minimal and mouse-driven, with no keyboard nudging and no extra instructional HUD beyond what is necessary for the app to remain understandable.

## User Stories

1. As a presenter, I want to select the shared area directly on my screen, so that I can choose the exact visible region without translating from a screenshot preview.
2. As a presenter, I want the selection overlay to appear only on the display I chose, so that multi-display setups stay predictable and implementation complexity stays lower.
3. As a presenter, I want the rest of the selected display dimmed behind the active crop, so that I can clearly see what will and will not be shared.
4. As a presenter, I want the overlay to use the live desktop underneath instead of a frozen screenshot, so that the experience feels immediate and native.
5. As a presenter, I want the existing saved crop to appear when I retake the region, so that I can adjust it instead of starting over.
6. As a presenter, I want to create a new crop by dragging, so that first-time selection is fast.
7. As a presenter, I want to move the current crop, so that I can reposition it precisely without redrawing it.
8. As a presenter, I want resize handles on all corners and side midpoints, so that I can adjust the crop from the edge that best matches my intent.
9. As a presenter, I want a minimum crop safeguard, so that I do not accidentally confirm a tiny unusable region.
10. As a presenter, I want `Enter` to confirm the crop, so that I can commit the selection without searching for a button.
11. As a presenter, I want `Esc` to cancel the overlay, so that I can safely back out without losing the previously saved region.
12. As a presenter, I want the overlay to feel polished and stable, so that setup does not feel like a fallback workflow.
13. As a presenter, I want the overlay interaction to remain mouse-friendly, so that I can complete selection without learning extra controls.
14. As a presenter, I want the app to preserve the selected display context while editing, so that the region always maps back to the correct display coordinates.
15. As a presenter, I want the app to reject accidental confirmations when no valid region exists, so that I do not end up with a broken shared area.
16. As a presenter, I want retaking a region to be faster than the initial setup, so that iterative adjustments are not disruptive during meeting prep.
17. As a presenter, I want the app to keep the currently saved region if I cancel a retake, so that I do not lose a working setup.
18. As a presenter, I want the share window workflow to remain the same after selection, so that this change improves selection UX without changing how I share into meeting tools.
19. As a developer, I want overlay geometry and interaction rules isolated from window presentation code, so that the trickiest logic can be tested without depending on AppKit lifecycle behavior.
20. As a developer, I want the overlay window lifecycle to be narrowly scoped, so that the app does not reintroduce the instability that caused the previous overlay implementation to be removed.
21. As a developer, I want selection state transitions to be explicit, so that choosing, confirming, canceling, and retaking remain easy to reason about.
22. As a developer, I want the app to continue working with the existing capture pipeline once a region is confirmed, so that this feature stays focused on selection UX rather than capture backend changes.

## Implementation Decisions

- The selection flow will move from an in-window screenshot editor to a dedicated overlay flow shown on the currently selected display only.
- The overlay will be translucent and will rely on the actual visible desktop beneath it rather than rendering a snapshot into the selector surface.
- The first version will prioritize a polished interaction model while constraining scope to one display at a time.
- The overlay will preload the current saved region when the user retakes selection.
- The interaction model will support three primary actions: create a new selection, move the existing selection, and resize via eight visible handles.
- Resize handles will exist at all four corners and the midpoint of each side to make the selection feel intentional and discoverable without adding a heavier instruction layer.
- Confirmation will be explicit through keyboard actions rather than implicit on mouse-up. `Enter` confirms the active valid selection and `Esc` cancels.
- The overlay itself will remain visually minimal for v1. A larger instruction HUD is intentionally deferred.
- Mouse interaction is in scope for v1. Keyboard nudging and fine-grained keyboard editing are out of scope.
- The current minimum size safeguard of `24x24` points will remain the validity threshold for confirmation.
- If the user cancels a retake, the previously saved region remains unchanged.
- If a capture session is already running when the user retakes the region, the implementation may choose the simplest safe behavior for v1, with stability favored over sophisticated live-edit semantics.
- The product state owner should continue to coordinate permission state, selected display, saved region, and capture state, but overlay presentation and geometry rules should be separated into narrower modules.
- A dedicated overlay coordination module should own presentation and dismissal of the selection overlay window so that AppKit lifecycle details do not leak into general app state management.
- A selection interaction module should encapsulate hit testing, drag interpretation, handle behavior, minimum-size enforcement, and coordinate conversion rules behind a small interface that can be tested in isolation.
- The existing capture-region model should remain the source of truth for the saved crop after confirmation, so downstream capture and share-window behavior do not need a parallel representation.
- The capture backend and share-window pipeline are unchanged by this feature except where necessary to integrate the new region-selection entry point.

## Testing Decisions

- A good test should validate external behavior and state transitions rather than internal implementation details such as specific view composition or AppKit window internals.
- Tests should focus on geometry and interaction behavior that is easy to regress and expensive to validate manually.
- The isolated selection interaction module should be covered with unit tests for creating selections, moving selections, resizing from each handle direction, clamping behavior, minimum-size enforcement, cancel behavior, and confirmation eligibility.
- State-coordination tests should cover the user-visible outcomes of starting selection, preloading an existing region, confirming a new region, and canceling without overwriting the old one.
- Manual testing should cover overlay presentation on the selected display, visual polish of dimming and handles, keyboard confirm/cancel behavior, focus handling, and end-to-end compatibility with the existing share window flow.
- Manual testing should also cover the simplest chosen behavior when retaking a region during an active share session, because that interaction crosses UI and capture lifecycle boundaries.
- Prior art for automated tests should follow the project’s current smoke-test philosophy: validate app-controlled behavior directly and avoid pretending to fully automate macOS permission prompts or conferencing-app integration.

## Out of Scope

- Multi-display overlay editing across all connected displays.
- Keyboard nudging or pixel-level keyboard adjustments.
- A richer instructional HUD or tutorial overlay.
- Replacing the current capture backend with a streaming architecture.
- Changing how the dedicated share window is exposed to conferencing tools.
- Automating macOS permission prompts or third-party app integration as part of this feature.
- Broader redesign of the main app window beyond removing the old screenshot-based selection path.

## Further Notes

- The repo history already indicates that a previous full-screen overlay approach caused lifecycle instability. This feature should explicitly avoid broad overlay complexity and keep presentation ownership narrow.
- The most important architectural tradeoff is to keep the polished selection UX while isolating geometry and window lifecycle concerns so they do not spread through the rest of the app.
- If later iterations require more guidance, a compact instruction HUD can be added without changing the core selection model.
