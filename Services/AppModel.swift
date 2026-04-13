import CoreGraphics
import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var displays: [DisplayInfo] = []
    @Published var selectedDisplayID: CGDirectDisplayID?
    @Published private(set) var selection: CaptureRegion?
    @Published private(set) var hasScreenAccess = false
    @Published private(set) var statusMessage = "Grant screen recording access to start."
    @Published private(set) var isChoosingRegion = false
    @Published private(set) var isSharing = false
    @Published private(set) var shareWindowAvailable = false
    @Published var selectionDraft: SelectionDraft?

    let recorder = ScreenRecorder()
    private lazy var previewWindowController = SharePreviewWindowController()

    init() {
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

        if selectedDisplay == nil {
            selectedDisplayID = displays.first?.id
        }
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

    func chooseRegion() async {
        guard hasScreenAccess else {
            statusMessage = "Grant screen recording access before choosing a region."
            return
        }

        guard let display = selectedDisplay else {
            statusMessage = "No display was detected."
            return
        }

        isChoosingRegion = true
        defer { isChoosingRegion = false }

        let cgImage = if AppEnvironment.isSmokeTest {
            MockCaptureFactory.makeImage(size: display.frame.size)
        } else {
            CGDisplayCreateImage(display.id)
        }

        guard let cgImage else {
            statusMessage = "Unable to snapshot the selected display."
            return
        }

        let image = NSImage(cgImage: cgImage, size: NSSize(width: display.frame.width, height: display.frame.height))
        selectionDraft = SelectionDraft(display: display, image: image)
        statusMessage = "Drag a region inside the preview, then confirm the crop."
    }

    func confirmSelection(_ rect: CGRect) {
        guard let draft = selectionDraft else { return }

        selection = CaptureRegion(displayID: draft.display.id, globalRect: rect.standardized)
        selectionDraft = nil
        statusMessage = "Region captured. Open the share window, then start capture when you're ready to share it."
    }

    func cancelSelectionDraft() {
        selectionDraft = nil
        statusMessage = selection == nil
            ? "Choose the area you want to mirror into the share window."
            : "Region locked. Start or resume the share window."
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
}
