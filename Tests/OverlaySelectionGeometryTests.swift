import CoreGraphics
import Testing
@testable import ScreenShare

struct OverlaySelectionGeometryTests {
    @Test
    func backgroundDragCreatesSelection() {
        var geometry = OverlaySelectionGeometry(canvasSize: CGSize(width: 300, height: 200))

        geometry.beginInteraction(at: CGPoint(x: 20, y: 30))
        geometry.updateInteraction(to: CGPoint(x: 160, y: 120))
        geometry.endInteraction(at: CGPoint(x: 160, y: 120))

        #expect(geometry.selectionRect == CGRect(x: 20, y: 30, width: 140, height: 90))
        #expect(geometry.canConfirm)
    }

    @Test
    func draggingInsideSelectionMovesIt() {
        var geometry = OverlaySelectionGeometry(
            canvasSize: CGSize(width: 300, height: 200),
            selectionRect: CGRect(x: 40, y: 50, width: 100, height: 80)
        )

        geometry.beginInteraction(at: CGPoint(x: 90, y: 90))
        geometry.updateInteraction(to: CGPoint(x: 190, y: 170))
        geometry.endInteraction(at: CGPoint(x: 190, y: 170))

        #expect(geometry.selectionRect == CGRect(x: 140, y: 120, width: 100, height: 80))
    }

    @Test
    func movingSelectionClampsToCanvas() {
        var geometry = OverlaySelectionGeometry(
            canvasSize: CGSize(width: 300, height: 200),
            selectionRect: CGRect(x: 40, y: 50, width: 100, height: 80)
        )

        geometry.beginInteraction(at: CGPoint(x: 90, y: 90))
        geometry.updateInteraction(to: CGPoint(x: 290, y: 190))
        geometry.endInteraction(at: CGPoint(x: 290, y: 190))

        #expect(geometry.selectionRect == CGRect(x: 200, y: 120, width: 100, height: 80))
    }

    @Test(arguments: [
        (OverlaySelectionHandle.topLeft, CGPoint(x: 30, y: 40), CGRect(x: 30, y: 40, width: 130, height: 120)),
        (.top, CGPoint(x: 100, y: 60), CGRect(x: 60, y: 60, width: 100, height: 100)),
        (.topRight, CGPoint(x: 220, y: 30), CGRect(x: 60, y: 30, width: 160, height: 130)),
        (.right, CGPoint(x: 240, y: 90), CGRect(x: 60, y: 80, width: 180, height: 80)),
        (.bottomRight, CGPoint(x: 210, y: 190), CGRect(x: 60, y: 80, width: 150, height: 110)),
        (.bottom, CGPoint(x: 100, y: 170), CGRect(x: 60, y: 80, width: 100, height: 90)),
        (.bottomLeft, CGPoint(x: 20, y: 180), CGRect(x: 20, y: 80, width: 140, height: 100)),
        (.left, CGPoint(x: 10, y: 100), CGRect(x: 10, y: 80, width: 150, height: 80))
    ])
    func resizeHandlesAdjustExpectedEdges(
        handle: OverlaySelectionHandle,
        dragPoint: CGPoint,
        expectedRect: CGRect
    ) {
        var geometry = OverlaySelectionGeometry(
            canvasSize: CGSize(width: 300, height: 220),
            selectionRect: CGRect(x: 60, y: 80, width: 100, height: 80)
        )

        let handlePoint = geometry.handles.first(where: { $0.handle == handle })!.center
        geometry.beginInteraction(at: handlePoint)
        geometry.updateInteraction(to: dragPoint)
        geometry.endInteraction(at: dragPoint)

        #expect(geometry.selectionRect == expectedRect)
    }

    @Test
    func handlesAreExposedForAllCornersAndEdges() {
        let geometry = OverlaySelectionGeometry(
            canvasSize: CGSize(width: 300, height: 200),
            selectionRect: CGRect(x: 40, y: 50, width: 100, height: 80)
        )

        #expect(geometry.handles.count == 8)
        #expect(geometry.handles.map(\.handle) == OverlaySelectionHandle.allCases)
    }

    @Test
    func hitTestingPrefersHandlesBeforeInteriorMove() {
        let geometry = OverlaySelectionGeometry(
            canvasSize: CGSize(width: 300, height: 200),
            selectionRect: CGRect(x: 40, y: 50, width: 100, height: 80)
        )

        #expect(geometry.hitTest(at: CGPoint(x: 40, y: 50)) == .handle(.topLeft))
        #expect(geometry.hitTest(at: CGPoint(x: 90, y: 90)) == .selection)
        #expect(geometry.hitTest(at: CGPoint(x: 8, y: 8)) == .background)
    }

    @Test
    func resizeCannotShrinkBelowMinimumSize() {
        var geometry = OverlaySelectionGeometry(
            minimumSelectionSize: 24,
            canvasSize: CGSize(width: 300, height: 200),
            selectionRect: CGRect(x: 40, y: 50, width: 60, height: 60)
        )

        let topLeft = geometry.handles.first(where: { $0.handle == .topLeft })!.center
        geometry.beginInteraction(at: topLeft)
        geometry.updateInteraction(to: CGPoint(x: 95, y: 105))
        geometry.endInteraction(at: CGPoint(x: 95, y: 105))

        #expect(geometry.selectionRect == CGRect(x: 76, y: 86, width: 24, height: 24))
        #expect(geometry.canConfirm)
    }

    @Test
    func undersizedSelectionCannotBeConfirmed() {
        var geometry = OverlaySelectionGeometry(
            minimumSelectionSize: 24,
            canvasSize: CGSize(width: 300, height: 200)
        )

        geometry.beginInteraction(at: CGPoint(x: 10, y: 10))
        geometry.updateInteraction(to: CGPoint(x: 20, y: 20))
        geometry.endInteraction(at: CGPoint(x: 20, y: 20))

        #expect(!geometry.canConfirm)
    }
}
