import AppKit
import CoreGraphics

enum MockCaptureFactory {
    static let displaySize = CGSize(width: 1440, height: 900)

    static func makeDisplay() -> DisplayInfo {
        DisplayInfo(
            id: 0,
            name: "Smoke Test Display",
            frame: CGRect(origin: .zero, size: displaySize),
            pixelSize: displaySize,
            scaleFactor: 1
        )
    }

    static func makeImage(size: CGSize = displaySize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return nil
        }

        let rect = CGRect(origin: .zero, size: size)
        context.setFillColor(CGColor(red: 0.09, green: 0.11, blue: 0.16, alpha: 1))
        context.fill(rect)

        let bands: [(CGFloat, CGFloat, CGFloat)] = [
            (0.96, 0.40, 0.24),
            (0.26, 0.64, 0.96),
            (0.28, 0.82, 0.55)
        ]

        for (index, band) in bands.enumerated() {
            let inset = CGFloat(index) * 90 + 80
            let bandRect = CGRect(x: inset, y: inset, width: size.width - inset * 1.4, height: 110)
            context.setFillColor(CGColor(red: band.0, green: band.1, blue: band.2, alpha: 1))
            context.fill(bandRect)
        }

        context.setStrokeColor(CGColor(gray: 1, alpha: 0.18))
        context.setLineWidth(2)
        for x in stride(from: 60, to: width, by: 120) {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: height))
        }
        for y in stride(from: 60, to: height, by: 120) {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: width, y: y))
        }
        context.strokePath()

        return context.makeImage()
    }
}
