# Plan: Overlay-Based Region Selection

> Source PRD: [docs/prd-overlay-selection.md](../docs/prd-overlay-selection.md)

## Architectural decisions

Durable decisions that apply across all phases:

- **Selection surface**: Region selection moves from an in-window screenshot editor to a dedicated translucent overlay shown only on the currently selected display.
- **Display scope**: Multi-display overlay behavior is out of scope for this feature. The active selected display is the only display that participates in selection.
- **Selection persistence**: The existing saved capture-region model remains the source of truth after selection is confirmed.
- **Interaction model**: The overlay supports mouse-driven create, move, and resize interactions, with visible handles at all four corners and the midpoint of each side.
- **Confirmation model**: Selection is explicit. `Enter` confirms a valid selection and `Esc` cancels the overlay without overwriting the previously saved region.
- **Validation rule**: The minimum valid selection remains `24x24`.
- **Visual scope**: The overlay stays visually minimal for v1 and uses the live desktop beneath a translucent dimming layer rather than a rendered screenshot.
- **Testing strategy**: Geometry and interaction state should be isolated behind a testable interface, while overlay-window lifecycle and display integration remain primarily manual-test territory.

---

## Phase 1: Overlay Shell

**User stories**: 1, 2, 3, 4, 10, 11, 12, 21

### What to build

Replace the screenshot draft entry point with a real overlay flow on the selected display. The app should be able to enter region-selection mode, present a translucent overlay on that display, capture focus for keyboard confirm/cancel, and return either a confirmed region or a canceled result back into the existing app state. The slice is complete when a user can choose a basic region through the overlay path and continue using the existing share workflow without the old screenshot editor.

### Acceptance criteria

- [x] Choosing a region opens a translucent overlay on the selected display only.
- [x] The overlay can be confirmed with `Enter` and canceled with `Esc`.
- [x] Confirming a valid region updates the app’s saved selection and closes the overlay.
- [x] Canceling the overlay closes it without clearing an already saved region.
- [x] The old screenshot-based draft flow is no longer the primary path for selecting a region.

---

## Phase 2: Preloaded Selection Editing

**User stories**: 5, 6, 7, 14, 15, 17, 18, 21, 22

### What to build

Make the overlay useful for normal iteration by preloading the existing saved region when retaking selection and supporting both first-time creation and subsequent editing. This phase should preserve the user’s current setup when they cancel, while ensuring that confirmed regions still feed directly into the current capture and share-window path.

### Acceptance criteria

- [x] Retaking a region shows the current saved region inside the overlay.
- [x] First-time selection works even when no region has been saved yet.
- [x] Canceling a retake preserves the previous saved region unchanged.
- [x] Confirming a retake replaces the saved region with the new selection.
- [x] Regions produced by the overlay continue to work with the existing capture and share-window flow.

---

## Phase 3: Handle-Based Resize And Move

**User stories**: 7, 8, 9, 12, 13, 19

### What to build

Add the polished editing model for the overlay: moving the current region, resizing from all corners and edge midpoints, and enforcing the minimum valid size during edits. This slice should establish the durable interaction rules that can be tested independently from the overlay window itself.

### Acceptance criteria

- [ ] The selection can be moved by dragging within the selected region.
- [ ] The selection can be resized from all four corners and all four side midpoints.
- [ ] Visible handles communicate the available resize affordances.
- [ ] Invalid sizes below the minimum threshold cannot be confirmed.
- [ ] Geometry and hit-testing rules are expressed through a narrow interface suitable for isolated automated tests.

---

## Phase 4: Retake During Active Sharing

**User stories**: 16, 18, 20, 22

### What to build

Define and implement the simplest safe end-to-end behavior when the user retakes the region while sharing is already active. The chosen behavior should favor stability and be explicit in the product flow so the user is not left guessing what happens to the running shared output while editing.

### Acceptance criteria

- [ ] Retaking a region while sharing is active follows one explicit, stable behavior rather than an undefined transition.
- [ ] The user can complete the retake flow without corrupting the saved selection state.
- [ ] After the retake flow completes, the app returns to a valid sharing state using the confirmed region or the prior region if canceled.
- [ ] The implementation does not reintroduce unstable overlay lifecycle behavior during active capture scenarios.

---

## Phase 5: Stability And Verification Pass

**User stories**: 12, 19, 20

### What to build

Harden the new selection path with focused automated coverage for geometry/state logic and a manual verification pass for overlay presentation, focus handling, and end-to-end usability. This phase closes the loop on the architectural goal of keeping the overlay polished while containing lifecycle risk.

### Acceptance criteria

- [ ] Automated tests cover creation, move, resize, clamping, minimum-size enforcement, confirmation eligibility, and cancel-preserves-old-selection behavior.
- [ ] Manual verification covers overlay presentation on the selected display, keyboard confirm/cancel behavior, and visual correctness of dimming and handles.
- [ ] Manual verification covers end-to-end selection through capture and share-window usage after both first-time selection and retake.
- [ ] Any stability issues uncovered during the earlier phases are resolved or documented before the feature is considered complete.
