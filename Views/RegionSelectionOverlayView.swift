import SwiftUI

struct RegionSelectionOverlayView: View {
    @ObservedObject var session: OverlaySelectionSession
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                overlaySurface
                instructionCard
                    .padding(20)
            }
            .contentShape(Rectangle())
            .onAppear {
                session.updateCanvasSize(proxy.size)
            }
            .onChange(of: proxy.size) { _, newSize in
                session.updateCanvasSize(newSize)
            }
            .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            session.beginOrUpdateDrag(
                                start: value.startLocation,
                                current: value.location
                            )
                        }
                    .onEnded { value in
                        session.finishDrag(at: value.location)
                    }
            )
        }
    }

    private var overlaySurface: some View {
        ZStack {
            selectionCutout

            if !session.selectionRectInView.isEmpty {
                let selection = session.selectionRectInView

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.white, lineWidth: 2)
                    .frame(width: selection.width, height: selection.height)
                    .position(x: selection.midX, y: selection.midY)
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 6)
            }
        }
        .background(Color.clear)
    }

    private var selectionCutout: some View {
        let fullRect = CGRect(origin: .zero, size: session.canvasSize)
        let selection = session.selectionRectInView

        return Path { path in
            path.addRect(fullRect)
            if !selection.isEmpty {
                path.addRoundedRect(
                    in: selection,
                    cornerSize: CGSize(width: 10, height: 10)
                )
            }
        }
        .fill(.black.opacity(0.45), style: FillStyle(eoFill: true))
    }

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Shared Area")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text("Drag to create a region on this display. Press Enter to confirm or Esc to cancel.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)

                Button("Confirm", action: onConfirm)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!session.canConfirm)
            }
        }
        .padding(16)
        .frame(maxWidth: 360, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.18))
        )
    }
}
