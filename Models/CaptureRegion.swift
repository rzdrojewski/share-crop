import CoreGraphics

struct CaptureRegion: Equatable, Sendable {
    let displayID: CGDirectDisplayID
    let globalRect: CGRect

    var size: CGSize {
        globalRect.size
    }

    var aspectRatio: CGFloat {
        guard globalRect.height > 0 else { return 16.0 / 9.0 }
        return globalRect.width / globalRect.height
    }
}
