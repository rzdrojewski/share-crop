import CoreGraphics
import Testing
@testable import ScreenShare

struct OverlaySelectionStateReducerTests {
    private let displayID: CGDirectDisplayID = 42

    @Test
    func cancelWithoutExistingSelectionLeavesStateEmpty() {
        let transition = OverlaySelectionStateReducer.resolve(
            currentSelection: nil,
            retakeSession: nil,
            outcome: .canceled
        )

        #expect(transition.selection == nil)
        #expect(transition.statusMessage == "Choose the area you want to mirror into the share window.")
        #expect(transition.resumeAction == nil)
    }

    @Test
    func cancelRetakePreservesPreviousSelection() {
        let previousSelection = makeRegion(x: 40, y: 50, width: 300, height: 200)
        let transition = OverlaySelectionStateReducer.resolve(
            currentSelection: makeRegion(x: 60, y: 70, width: 120, height: 90),
            retakeSession: OverlaySelectionRetakeSession(previousSelection: previousSelection, wasSharing: false),
            outcome: .canceled
        )

        #expect(transition.selection == previousSelection)
        #expect(transition.statusMessage == "Region locked. Start or resume the share window.")
        #expect(transition.resumeAction == nil)
    }

    @Test
    func cancelActiveShareRetakeRestoresPreviousSelectionAndResumes() {
        let previousSelection = makeRegion(x: 40, y: 50, width: 300, height: 200)
        let transition = OverlaySelectionStateReducer.resolve(
            currentSelection: previousSelection,
            retakeSession: OverlaySelectionRetakeSession(previousSelection: previousSelection, wasSharing: true),
            outcome: .canceled
        )

        #expect(transition.selection == previousSelection)
        #expect(transition.statusMessage == "Retake canceled. Restarting capture with the previous region.")
        #expect(transition.resumeAction == OverlaySelectionResumeAction(region: previousSelection, canceledRetake: true))
    }

    @Test
    func confirmingRetakeWhileSharingResumesWithConfirmedSelection() {
        let confirmedSelection = makeRegion(x: 100, y: 120, width: 320, height: 180)
        let transition = OverlaySelectionStateReducer.resolve(
            currentSelection: makeRegion(x: 40, y: 50, width: 300, height: 200),
            retakeSession: OverlaySelectionRetakeSession(previousSelection: makeRegion(x: 40, y: 50, width: 300, height: 200), wasSharing: true),
            outcome: .confirmed(confirmedSelection)
        )

        #expect(transition.selection == confirmedSelection)
        #expect(transition.statusMessage == "Region updated. Restarting capture with the new selection.")
        #expect(transition.resumeAction == OverlaySelectionResumeAction(region: confirmedSelection, canceledRetake: false))
    }

    private func makeRegion(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CaptureRegion {
        CaptureRegion(
            displayID: displayID,
            globalRect: CGRect(x: x, y: y, width: width, height: height)
        )
    }
}
