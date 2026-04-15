import Foundation

struct OverlaySelectionRetakeSession: Equatable {
    let previousSelection: CaptureRegion
    let wasSharing: Bool
}

enum OverlaySelectionOutcome: Equatable {
    case confirmed(CaptureRegion)
    case canceled
}

struct OverlaySelectionResumeAction: Equatable {
    let region: CaptureRegion
    let canceledRetake: Bool
}

struct OverlaySelectionStateTransition: Equatable {
    let selection: CaptureRegion?
    let statusMessage: String
    let resumeAction: OverlaySelectionResumeAction?
}

enum OverlaySelectionStateReducer {
    static func resolve(
        currentSelection: CaptureRegion?,
        retakeSession: OverlaySelectionRetakeSession?,
        outcome: OverlaySelectionOutcome
    ) -> OverlaySelectionStateTransition {
        switch outcome {
        case .confirmed(let selection):
            if let retakeSession, retakeSession.wasSharing {
                return OverlaySelectionStateTransition(
                    selection: selection,
                    statusMessage: "Region updated. Restarting capture with the new selection.",
                    resumeAction: OverlaySelectionResumeAction(region: selection, canceledRetake: false)
                )
            }

            return OverlaySelectionStateTransition(
                selection: selection,
                statusMessage: "Region captured. Open the share window, then start capture when you're ready to share it.",
                resumeAction: nil
            )
        case .canceled:
            if let retakeSession {
                if retakeSession.wasSharing {
                    return OverlaySelectionStateTransition(
                        selection: retakeSession.previousSelection,
                        statusMessage: "Retake canceled. Restarting capture with the previous region.",
                        resumeAction: OverlaySelectionResumeAction(region: retakeSession.previousSelection, canceledRetake: true)
                    )
                }

                return OverlaySelectionStateTransition(
                    selection: retakeSession.previousSelection,
                    statusMessage: "Region locked. Start or resume the share window.",
                    resumeAction: nil
                )
            }

            return OverlaySelectionStateTransition(
                selection: currentSelection,
                statusMessage: currentSelection == nil
                    ? "Choose the area you want to mirror into the share window."
                    : "Region locked. Start or resume the share window.",
                resumeAction: nil
            )
        }
    }
}
