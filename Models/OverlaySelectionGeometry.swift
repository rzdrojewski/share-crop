import CoreGraphics

enum OverlaySelectionHandle: CaseIterable {
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
}

struct OverlaySelectionHandleInfo: Equatable {
    let handle: OverlaySelectionHandle
    let center: CGPoint
}

enum OverlaySelectionHitTarget: Equatable {
    case background
    case selection
    case handle(OverlaySelectionHandle)
}

struct OverlaySelectionGeometry {
    private enum Interaction {
        case create(startPoint: CGPoint)
        case move(initialRect: CGRect, startPoint: CGPoint)
        case resize(handle: OverlaySelectionHandle, initialRect: CGRect)
    }

    let minimumSelectionSize: CGFloat
    let handleHitSize: CGFloat
    var canvasSize: CGSize {
        didSet {
            selectionRect = clampedSelectionRect(selectionRect)
        }
    }

    private(set) var selectionRect: CGRect
    private var interaction: Interaction?

    init(
        minimumSelectionSize: CGFloat = 24,
        handleHitSize: CGFloat = 18,
        canvasSize: CGSize = .zero,
        selectionRect: CGRect = .zero
    ) {
        self.minimumSelectionSize = minimumSelectionSize
        self.handleHitSize = handleHitSize
        self.canvasSize = canvasSize
        self.selectionRect = selectionRect.standardized
        self.selectionRect = clampedSelectionRect(self.selectionRect)
    }

    var canConfirm: Bool {
        selectionRect.width >= minimumSelectionSize && selectionRect.height >= minimumSelectionSize
    }

    var handles: [OverlaySelectionHandleInfo] {
        guard !selectionRect.isEmpty else { return [] }

        return [
            OverlaySelectionHandleInfo(handle: .topLeft, center: CGPoint(x: selectionRect.minX, y: selectionRect.minY)),
            OverlaySelectionHandleInfo(handle: .top, center: CGPoint(x: selectionRect.midX, y: selectionRect.minY)),
            OverlaySelectionHandleInfo(handle: .topRight, center: CGPoint(x: selectionRect.maxX, y: selectionRect.minY)),
            OverlaySelectionHandleInfo(handle: .right, center: CGPoint(x: selectionRect.maxX, y: selectionRect.midY)),
            OverlaySelectionHandleInfo(handle: .bottomRight, center: CGPoint(x: selectionRect.maxX, y: selectionRect.maxY)),
            OverlaySelectionHandleInfo(handle: .bottom, center: CGPoint(x: selectionRect.midX, y: selectionRect.maxY)),
            OverlaySelectionHandleInfo(handle: .bottomLeft, center: CGPoint(x: selectionRect.minX, y: selectionRect.maxY)),
            OverlaySelectionHandleInfo(handle: .left, center: CGPoint(x: selectionRect.minX, y: selectionRect.midY))
        ]
    }

    mutating func setSelectionRect(_ rect: CGRect?) {
        selectionRect = clampedSelectionRect((rect ?? .zero).standardized)
        interaction = nil
    }

    func hitTest(at point: CGPoint) -> OverlaySelectionHitTarget {
        let point = clamped(point)

        if let handle = handles.first(where: { handleFrame(for: $0.center).contains(point) })?.handle {
            return .handle(handle)
        }

        if selectionRect.contains(point) {
            return .selection
        }

        return .background
    }

    mutating func beginInteraction(at point: CGPoint) {
        let point = clamped(point)

        switch hitTest(at: point) {
        case .handle(let handle):
            interaction = .resize(handle: handle, initialRect: selectionRect)
        case .selection:
            interaction = .move(initialRect: selectionRect, startPoint: point)
        case .background:
            interaction = .create(startPoint: point)
            selectionRect = CGRect(origin: point, size: .zero)
        }
    }

    mutating func updateInteraction(to point: CGPoint) {
        guard let interaction else { return }
        let point = clamped(point)

        switch interaction {
        case .create(let startPoint):
            selectionRect = CGRect(
                x: min(startPoint.x, point.x),
                y: min(startPoint.y, point.y),
                width: abs(point.x - startPoint.x),
                height: abs(point.y - startPoint.y)
            )
        case .move(let initialRect, let startPoint):
            selectionRect = clampedSelectionRect(
                initialRect.offsetBy(dx: point.x - startPoint.x, dy: point.y - startPoint.y)
            )
        case .resize(let handle, let initialRect):
            selectionRect = resizedRect(from: initialRect, handle: handle, point: point)
        }
    }

    mutating func endInteraction(at point: CGPoint) {
        updateInteraction(to: point)
        interaction = nil
    }

    private func resizedRect(from rect: CGRect, handle: OverlaySelectionHandle, point: CGPoint) -> CGRect {
        var minX = rect.minX
        var maxX = rect.maxX
        var minY = rect.minY
        var maxY = rect.maxY

        switch handle {
        case .topLeft:
            minX = min(max(point.x, 0), rect.maxX - minimumSelectionSize)
            minY = min(max(point.y, 0), rect.maxY - minimumSelectionSize)
        case .top:
            minY = min(max(point.y, 0), rect.maxY - minimumSelectionSize)
        case .topRight:
            maxX = max(min(point.x, canvasSize.width), rect.minX + minimumSelectionSize)
            minY = min(max(point.y, 0), rect.maxY - minimumSelectionSize)
        case .right:
            maxX = max(min(point.x, canvasSize.width), rect.minX + minimumSelectionSize)
        case .bottomRight:
            maxX = max(min(point.x, canvasSize.width), rect.minX + minimumSelectionSize)
            maxY = max(min(point.y, canvasSize.height), rect.minY + minimumSelectionSize)
        case .bottom:
            maxY = max(min(point.y, canvasSize.height), rect.minY + minimumSelectionSize)
        case .bottomLeft:
            minX = min(max(point.x, 0), rect.maxX - minimumSelectionSize)
            maxY = max(min(point.y, canvasSize.height), rect.minY + minimumSelectionSize)
        case .left:
            minX = min(max(point.x, 0), rect.maxX - minimumSelectionSize)
        }

        return clampedSelectionRect(
            CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        )
    }

    private func clampedSelectionRect(_ rect: CGRect) -> CGRect {
        guard canvasSize.width > 0, canvasSize.height > 0, !rect.isEmpty else {
            return rect.isEmpty ? .zero : rect
        }

        let width = min(rect.width, canvasSize.width)
        let height = min(rect.height, canvasSize.height)
        let origin = CGPoint(
            x: min(max(rect.minX, 0), canvasSize.width - width),
            y: min(max(rect.minY, 0), canvasSize.height - height)
        )

        return CGRect(origin: origin, size: CGSize(width: width, height: height)).standardized
    }

    private func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), canvasSize.width),
            y: min(max(point.y, 0), canvasSize.height)
        )
    }

    private func handleFrame(for center: CGPoint) -> CGRect {
        CGRect(
            x: center.x - handleHitSize / 2,
            y: center.y - handleHitSize / 2,
            width: handleHitSize,
            height: handleHitSize
        )
    }
}
