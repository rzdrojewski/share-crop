import SwiftUI

struct SelectionEditorView: View {
    let draft: SelectionDraft
    let onCancel: () -> Void
    let onConfirm: (CGRect) -> Void

    @State private var dragStart: CGPoint?
    @State private var currentPoint: CGPoint?
    @State private var canvasRect: CGRect = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose Shared Area")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text("Drag over the screenshot to define the crop. This stays inside the app window, so it avoids the full-screen overlay that was crashing.")
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                let imageRect = fittedRect(in: proxy.size, contentSize: draft.display.frame.size)

                ZStack {
                    Color.black.opacity(0.08)

                    Image(nsImage: draft.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageRect.width, height: imageRect.height)
                        .position(x: imageRect.midX, y: imageRect.midY)

                    selectionOverlay(in: imageRect)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(Rectangle())
                .onAppear {
                    canvasRect = imageRect
                }
                .onChange(of: proxy.size) { _, _ in
                    canvasRect = imageRect
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard imageRect.contains(value.location) else { return }
                            if dragStart == nil {
                                dragStart = clamped(value.startLocation, to: imageRect)
                            }
                            currentPoint = clamped(value.location, to: imageRect)
                        }
                        .onEnded { value in
                            guard dragStart != nil else { return }
                            currentPoint = clamped(value.location, to: imageRect)
                        }
                )
            }
            .frame(minHeight: 360)

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)

                Button("Confirm Crop") {
                    if let rect = selectedDisplayRect() {
                        onConfirm(rect)
                    }
                }
                .disabled(selectedDisplayRect() == nil)
            }
        }
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func selectionOverlay(in imageRect: CGRect) -> some View {
        let selection = selectedImageRect()
        Path { path in
            path.addRect(imageRect)
            if !selection.isEmpty {
                path.addRect(selection)
            }
        }
        .fill(.black.opacity(0.35), style: FillStyle(eoFill: true))

        if !selection.isEmpty {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white, lineWidth: 2)
                .frame(width: selection.width, height: selection.height)
                .position(x: selection.midX, y: selection.midY)
        }
    }

    private func fittedRect(in container: CGSize, contentSize: CGSize) -> CGRect {
        let scale = min(container.width / contentSize.width, container.height / contentSize.height)
        let size = CGSize(width: contentSize.width * scale, height: contentSize.height * scale)
        return CGRect(
            x: (container.width - size.width) / 2,
            y: (container.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    private func clamped(_ point: CGPoint, to rect: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, rect.minX), rect.maxX),
            y: min(max(point.y, rect.minY), rect.maxY)
        )
    }

    private func selectedImageRect() -> CGRect {
        guard let dragStart, let currentPoint else { return .zero }
        return CGRect(
            x: min(dragStart.x, currentPoint.x),
            y: min(dragStart.y, currentPoint.y),
            width: abs(currentPoint.x - dragStart.x),
            height: abs(currentPoint.y - dragStart.y)
        )
    }

    private func selectedDisplayRect() -> CGRect? {
        let selectionRect = selectedImageRect()
        guard selectionRect.width >= 24, selectionRect.height >= 24, !canvasRect.isEmpty else { return nil }

        let displayFrame = draft.display.frame
        let relativeX = (selectionRect.minX - canvasRect.minX) / canvasRect.width
        let relativeMaxY = (selectionRect.maxY - canvasRect.minY) / canvasRect.height
        let relativeWidth = selectionRect.width / canvasRect.width
        let relativeHeight = selectionRect.height / canvasRect.height

        return CGRect(
            x: displayFrame.minX + relativeX * displayFrame.width,
            y: displayFrame.minY + (1 - relativeMaxY) * displayFrame.height,
            width: relativeWidth * displayFrame.width,
            height: relativeHeight * displayFrame.height
        )
    }
}
