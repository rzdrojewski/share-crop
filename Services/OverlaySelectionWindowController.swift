import AppKit
import SwiftUI

@MainActor
final class OverlaySelectionWindowController: NSWindowController, NSWindowDelegate {
    struct ConfirmedSelection {
        let displayID: CGDirectDisplayID
        let globalRect: CGRect
    }

    enum Result {
        case confirmed(ConfirmedSelection)
        case canceled
    }

    private final class OverlayWindow: NSWindow {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { true }
    }

    private let display: DisplayInfo
    private let session: OverlaySelectionSession
    private let completion: (Result) -> Void
    private var keyMonitor: Any?
    private var finished = false

    init(
        display: DisplayInfo,
        initialSelection: CaptureRegion? = nil,
        completion: @escaping (Result) -> Void
    ) {
        self.display = display
        self.session = OverlaySelectionSession(display: display, initialSelection: initialSelection)
        self.completion = completion

        let window = OverlayWindow(
            contentRect: display.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        window.delegate = nil

        let hostingView = NSHostingView(
            rootView: RegionSelectionOverlayView(
                session: session,
                onCancel: {},
                onConfirm: {}
            )
        )
        hostingView.frame = CGRect(origin: .zero, size: display.frame.size)

        window.contentView = hostingView

        super.init(window: window)

        window.delegate = self
        hostingView.rootView = RegionSelectionOverlayView(
            session: session,
            onCancel: { [weak self] in self?.cancel() },
            onConfirm: { [weak self] in self?.confirmIfPossible() }
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        guard let window else { return }

        installKeyMonitor()
        window.setFrame(display.frame, display: true)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        guard !finished else { return }
        finish(.canceled)
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.window?.isKeyWindow == true else {
                return event
            }

            switch event.keyCode {
            case 36, 76:
                self.confirmIfPossible()
                return nil
            case 53:
                self.cancel()
                return nil
            default:
                return event
            }
        }
    }

    private func confirmIfPossible() {
        guard let rect = session.confirmedSelection else { return }
        finish(.confirmed(rect))
    }

    private func cancel() {
        finish(.canceled)
    }

    private func finish(_ result: Result) {
        guard !finished else { return }
        finished = true

        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }

        window?.orderOut(nil)
        close()
        completion(result)
    }
}

@MainActor
final class OverlaySelectionSession: ObservableObject {
    private let minimumSelectionSize: CGFloat = 24
    private let display: DisplayInfo
    private let initialSelection: CaptureRegion?

    @Published private(set) var dragStart: CGPoint?
    @Published private(set) var currentPoint: CGPoint?
    @Published private(set) var canvasSize: CGSize = .zero

    init(display: DisplayInfo, initialSelection: CaptureRegion? = nil) {
        self.display = display
        if let initialSelection, initialSelection.displayID == display.id {
            self.initialSelection = initialSelection
        } else {
            self.initialSelection = nil
        }
    }

    var selectionRectInView: CGRect {
        guard let dragStart, let currentPoint else { return .zero }

        return CGRect(
            x: min(dragStart.x, currentPoint.x),
            y: min(dragStart.y, currentPoint.y),
            width: abs(currentPoint.x - dragStart.x),
            height: abs(currentPoint.y - dragStart.y)
        )
    }

    var confirmedSelection: OverlaySelectionWindowController.ConfirmedSelection? {
        let selection = selectionRectInView
        guard
            selection.width >= minimumSelectionSize,
            selection.height >= minimumSelectionSize,
            canvasSize.width > 0,
            canvasSize.height > 0
        else {
            return nil
        }

        return OverlaySelectionWindowController.ConfirmedSelection(
            displayID: display.id,
            globalRect: CGRect(
                x: display.frame.minX + selection.minX,
                y: display.frame.minY + (canvasSize.height - selection.maxY),
                width: selection.width,
                height: selection.height
            )
        )
    }

    var canConfirm: Bool {
        confirmedSelection != nil
    }

    func updateCanvasSize(_ size: CGSize) {
        canvasSize = size

        guard dragStart == nil, currentPoint == nil else { return }
        guard let initialSelection else { return }

        let selection = rectInView(for: initialSelection.globalRect, canvasHeight: size.height)
        dragStart = selection.origin
        currentPoint = CGPoint(x: selection.maxX, y: selection.maxY)
    }

    func beginOrUpdateDrag(start startPoint: CGPoint, current point: CGPoint) {
        dragStart = clamped(startPoint)
        currentPoint = clamped(point)
    }

    func finishDrag(at point: CGPoint) {
        guard dragStart != nil else { return }
        currentPoint = clamped(point)
    }

    private func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), canvasSize.width),
            y: min(max(point.y, 0), canvasSize.height)
        )
    }

    private func rectInView(for globalRect: CGRect, canvasHeight: CGFloat) -> CGRect {
        CGRect(
            x: globalRect.minX - display.frame.minX,
            y: canvasHeight - (globalRect.maxY - display.frame.minY),
            width: globalRect.width,
            height: globalRect.height
        ).standardized
    }
}
