import CoreGraphics
import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    private enum StorageKeys {
        static let selectedDisplayID = "selectedDisplayID"
    }

    @Published private(set) var displays: [DisplayInfo] = []
    @Published var selectedDisplayID: CGDirectDisplayID?
    @Published private(set) var selection: CaptureRegion?
    @Published private(set) var hasScreenAccess = false
    @Published private(set) var statusMessage = "Grant screen recording access to start."
    @Published private(set) var isChoosingRegion = false
    @Published private(set) var isSharing = false
    @Published private(set) var shareWindowAvailable = false

    let recorder = ScreenRecorder()
    private lazy var previewWindowController = SharePreviewWindowController()
    private var overlaySelectionController: OverlaySelectionWindowController?
    private var activeRetakeSession: OverlaySelectionRetakeSession?

    init() {
        selectedDisplayID = Self.loadPersistedDisplayID()
        refreshDisplays()
        refreshPermissionStatus()

        if AppEnvironment.isSmokeTest {
            bootstrapSmokeTest()
        }
    }

    var selectedDisplay: DisplayInfo? {
        guard let selectedDisplayID else { return displays.first }
        return displays.first(where: { $0.id == selectedDisplayID })
    }

    func refreshDisplays() {
        displays = DisplayInfo.currentDisplays()

        if let selectedDisplayID, displays.contains(where: { $0.id == selectedDisplayID }) {
            return
        }

        let fallbackDisplayID = displays.first?.id
        selectedDisplayID = fallbackDisplayID
        Self.persistDisplayID(fallbackDisplayID)
    }

    func setSelectedDisplayID(_ displayID: CGDirectDisplayID?) {
        selectedDisplayID = displayID
        Self.persistDisplayID(displayID)
    }

    func refreshPermissionStatus() {
        if AppEnvironment.isSmokeTest {
            hasScreenAccess = true
            statusMessage = "Smoke test mode enabled."
            return
        }

        hasScreenAccess = CGPreflightScreenCaptureAccess()
        if hasScreenAccess {
            statusMessage = selection == nil
                ? "Choose the area you want to mirror into the share window."
                : "Region locked. Start or resume the share window."
        }
    }

    func requestScreenAccess() {
        hasScreenAccess = CGPreflightScreenCaptureAccess()
        if hasScreenAccess {
            statusMessage = "Screen recording access already granted."
            return
        }

        let granted = CGRequestScreenCaptureAccess()
        hasScreenAccess = granted || CGPreflightScreenCaptureAccess()
        statusMessage = hasScreenAccess
            ? "Access granted. Choose the area you want to share."
            : "Screen recording access is required. macOS may need you to enable it in System Settings."
    }

    func chooseRegion() {
        guard hasScreenAccess else {
            statusMessage = "Grant screen recording access before choosing a region."
            return
        }

        guard let display = selectedDisplay else {
            statusMessage = "No display was detected."
            return
        }

        guard overlaySelectionController == nil else {
            statusMessage = "Finish the current region selection before opening another overlay."
            return
        }

        if isSharing, let previousSelection = selection {
            isChoosingRegion = true
            activeRetakeSession = OverlaySelectionRetakeSession(previousSelection: previousSelection, wasSharing: true)
            statusMessage = "Pausing capture so you can retake the shared region."
            previewWindowController.showWaitingState()

            Task { @MainActor [weak self] in
                guard let self else { return }

                await self.recorder.stopCapture()
                self.isSharing = false
                self.presentSelectionOverlay(on: display)
                self.statusMessage = "Capture paused while you retake the region. Press Enter to confirm or Esc to keep the previous region."
            }
            return
        }

        presentSelectionOverlay(on: display)
        statusMessage = "Drag on the selected display to define the shared area. Press Enter to confirm or Esc to cancel."
    }

    func startSharing() async throws {
        guard let display = selectedDisplay else {
            statusMessage = "Pick a display first."
            return
        }

        guard let selection, selection.displayID == display.id else {
            statusMessage = "Choose a region on the selected display first."
            return
        }

        do {
            try await recorder.startCapture(display: display, selection: selection)
            previewWindowController.showWaitingState()
            previewWindowController.show(region: selection)
            isSharing = true
            shareWindowAvailable = true
            statusMessage = "Capture started. Share the “Share Crop” window in Teams, Zoom, or Slack."
        } catch {
            isSharing = false
            statusMessage = "Capture failed: \(error.localizedDescription)"
            throw error
        }
    }

    func stopSharing() async {
        await recorder.stopCapture()
        isSharing = false
        statusMessage = "Capture paused. Your region is still saved."
    }

    func showShareWindow() {
        guard let selection else {
            statusMessage = "Choose a region before opening the share window."
            return
        }

        previewWindowController.show(region: selection)
        shareWindowAvailable = true
        statusMessage = "The “Share Crop” window is open. Share that window in Teams."
    }

    private func bootstrapSmokeTest() {
        guard let display = displays.first else { return }

        let defaultRect = CGRect(x: 180, y: 180, width: 960, height: 540)
        selection = CaptureRegion(displayID: display.id, globalRect: defaultRect)
        statusMessage = "Smoke test mode armed."

        Task { @MainActor in
            try? await startSharing()
        }
    }

    private static func persistDisplayID(_ displayID: CGDirectDisplayID?) {
        let defaults = UserDefaults.standard
        guard let displayID else {
            defaults.removeObject(forKey: StorageKeys.selectedDisplayID)
            return
        }

        defaults.set(UInt32(displayID), forKey: StorageKeys.selectedDisplayID)
    }

    private static func loadPersistedDisplayID() -> CGDirectDisplayID? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: StorageKeys.selectedDisplayID) != nil else {
            return nil
        }

        return CGDirectDisplayID(defaults.integer(forKey: StorageKeys.selectedDisplayID))
    }

    private func presentSelectionOverlay(on display: DisplayInfo) {
        isChoosingRegion = true

        let controller = OverlaySelectionWindowController(
            display: display,
            initialSelection: selection
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                self?.finishRegionSelection(result)
            }
        }

        overlaySelectionController = controller
        controller.present()
    }

    private func display(for displayID: CGDirectDisplayID) -> DisplayInfo? {
        displays.first(where: { $0.id == displayID })
    }

    private func finishRegionSelection(_ result: OverlaySelectionWindowController.Result) {
        overlaySelectionController = nil
        isChoosingRegion = false
        let retakeSession = activeRetakeSession
        activeRetakeSession = nil

        let outcome: OverlaySelectionOutcome
        switch result {
        case .confirmed(let rect):
            outcome = .confirmed(
                CaptureRegion(displayID: rect.displayID, globalRect: rect.globalRect.standardized)
            )
        case .canceled:
            outcome = .canceled
        }

        let transition = OverlaySelectionStateReducer.resolve(
            currentSelection: selection,
            retakeSession: retakeSession,
            outcome: outcome
        )
        selection = transition.selection
        statusMessage = transition.statusMessage

        if let resumeAction = transition.resumeAction {
            resumeSharing(with: resumeAction.region, canceledRetake: resumeAction.canceledRetake)
        }
    }

    private func resumeSharing(with region: CaptureRegion?, canceledRetake: Bool) {
        guard let region else {
            statusMessage = "Choose a region before resuming capture."
            return
        }

        guard let display = display(for: region.displayID) else {
            shareWindowAvailable = false
            statusMessage = "The display for the saved region is no longer available."
            return
        }

        previewWindowController.showWaitingState()
        previewWindowController.show(region: region)
        shareWindowAvailable = true

        Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await self.recorder.startCapture(display: display, selection: region)
                self.isSharing = true
                self.statusMessage = canceledRetake
                    ? "Retake canceled. Capture resumed with the previous region."
                    : "Retake complete. Capture resumed with the updated region."
            } catch {
                self.isSharing = false
                self.statusMessage = canceledRetake
                    ? "Retake canceled, but capture could not resume: \(error.localizedDescription)"
                    : "Retake confirmed, but capture could not resume: \(error.localizedDescription)"
            }
        }
    }
}
