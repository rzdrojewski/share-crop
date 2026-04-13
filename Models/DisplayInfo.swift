import AppKit
import CoreGraphics

struct DisplayInfo: Identifiable, Equatable, Sendable {
    let id: CGDirectDisplayID
    let name: String
    let frame: CGRect
    let pixelSize: CGSize
    let scaleFactor: CGFloat

    var description: String {
        let points = "\(Int(frame.width))×\(Int(frame.height)) pt"
        let pixels = "\(Int(pixelSize.width))×\(Int(pixelSize.height)) px"
        return "\(name) • \(points) • \(pixels)"
    }

    static func currentDisplays() -> [DisplayInfo] {
        if AppEnvironment.isSmokeTest {
            return [MockCaptureFactory.makeDisplay()]
        }

        return NSScreen.screens.compactMap { screen -> DisplayInfo? in
            guard
                let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            else {
                return nil
            }

            let displayID = CGDirectDisplayID(screenNumber.uint32Value)
            let pixelWidth = CGFloat(CGDisplayPixelsWide(displayID))
            let pixelHeight = CGFloat(CGDisplayPixelsHigh(displayID))
            return DisplayInfo(
                id: displayID,
                name: screen.localizedName,
                frame: screen.frame,
                pixelSize: CGSize(width: pixelWidth, height: pixelHeight),
                scaleFactor: screen.backingScaleFactor
            )
        }
        .sorted { lhs, rhs in
            if lhs.frame.minY == rhs.frame.minY {
                return lhs.frame.minX < rhs.frame.minX
            }
            return lhs.frame.minY < rhs.frame.minY
        }
    }
}
