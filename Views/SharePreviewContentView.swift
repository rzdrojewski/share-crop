import SwiftUI

struct SharePreviewContentView: View {
    @ObservedObject var recorder: ScreenRecorder

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let image = recorder.latestFrame {
                GeometryReader { proxy in
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: proxy.size.width, maxHeight: proxy.size.height)
                        .padding(20)
                }
            } else if let errorMessage = recorder.lastErrorMessage {
                overlayText(title: "Capture Error", body: errorMessage)
            } else {
                overlayText(
                    title: "Waiting For Frames",
                    body: "Choose a region and start capture. This surface mirrors exactly what the share window will show."
                )
            }
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 300)
    }

    @ViewBuilder
    private func overlayText(title: String, body: String) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.76))
                .frame(maxWidth: 420)
        }
    }
}
