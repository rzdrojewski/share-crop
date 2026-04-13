import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ScreenRecorderError: LocalizedError {
    case displayUnavailable

    var errorDescription: String? {
        switch self {
        case .displayUnavailable:
            return "The selected display is no longer available."
        }
    }
}

@MainActor
final class ScreenRecorder: NSObject, ObservableObject {
    @Published private(set) var latestFrame: NSImage?
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var isRunning = false

    private let captureQueue = DispatchQueue(label: "ScreenShare.capture-output", qos: .userInitiated)
    private var captureTimer: DispatchSourceTimer?

    func startCapture(display: DisplayInfo, selection: CaptureRegion) async throws {
        await stopCapture()

        guard CGDisplayIsActive(display.id) != 0 else {
            throw ScreenRecorderError.displayUnavailable
        }

        latestFrame = nil
        lastErrorMessage = nil

        let timer = DispatchSource.makeTimerSource(queue: captureQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(100), leeway: .milliseconds(20))
        timer.setEventHandler(handler: Self.makeCaptureHandler(display: display, selection: selection))
        captureTimer = timer
        timer.resume()
        isRunning = true
    }

    func stopCapture() async {
        captureTimer?.cancel()
        captureTimer = nil
        isRunning = false
    }

    override init() {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFrameNotification(_:)),
            name: .screenRecorderFrameReady,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleFrameNotification(_ notification: Notification) {
        guard let image = notification.object as? NSImage else { return }
        update(frame: image)
    }

    private func update(frame: NSImage) {
        latestFrame = frame
        lastErrorMessage = nil

        if AppEnvironment.isSmokeTest {
            persistSmokeFrame(frame)
        }
    }

    private func update(error: Error) {
        lastErrorMessage = error.localizedDescription
    }

    nonisolated private static func cropImage(_ image: CGImage, for display: DisplayInfo, selection: CaptureRegion) -> CGImage? {
        let relativeRect = selection.globalRect.offsetBy(dx: -display.frame.minX, dy: -display.frame.minY)
        guard relativeRect.width > 0, relativeRect.height > 0 else {
            return image
        }

        let scaleX = CGFloat(image.width) / display.frame.width
        let scaleY = CGFloat(image.height) / display.frame.height
        let cropRect = CGRect(
            x: relativeRect.minX * scaleX,
            y: CGFloat(image.height) - (relativeRect.maxY * scaleY),
            width: relativeRect.width * scaleX,
            height: relativeRect.height * scaleY
        ).integral

        return image.cropping(to: cropRect.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height)))
    }

    nonisolated private static func captureFrame(display: DisplayInfo, selection: CaptureRegion) -> NSImage? {
        let sourceImage = if display.id == 0 {
            MockCaptureFactory.makeImage(size: display.frame.size)
        } else {
            CGDisplayCreateImage(display.id)
        }

        guard let cgImage = sourceImage else {
            return nil
        }

        let finalImage = cropImage(cgImage, for: display, selection: selection) ?? cgImage
        let size = NSSize(width: finalImage.width, height: finalImage.height)
        return NSImage(cgImage: finalImage, size: size)
    }

    nonisolated private static func makeCaptureHandler(display: DisplayInfo, selection: CaptureRegion) -> @Sendable () -> Void {
        return {
            guard let image = captureFrame(display: display, selection: selection) else {
                return
            }

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .screenRecorderFrameReady, object: image)
            }
        }
    }

    private func persistSmokeFrame(_ image: NSImage) {
        guard
            let outputPath = AppEnvironment.smokeOutputPath,
            let tiffData = image.tiffRepresentation,
            let imageSource = CGImageSourceCreateWithData(tiffData as CFData, nil),
            let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
            let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: outputPath) as CFURL, UTType.png.identifier as CFString, 1, nil)
        else {
            return
        }

        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)
    }
}

extension Notification.Name {
    static let screenRecorderFrameReady = Notification.Name("ScreenRecorder.frameReady")
}
