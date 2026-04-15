import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            displaySection
            regionSection
            previewSection
            actionSection
            footer
        }
        .padding(28)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .task {
            model.refreshDisplays()
            model.refreshPermissionStatus()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Share Only What Matters")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("This app mirrors a selected screen region into a normal macOS window. Share that window in Zoom, Teams, Slack, or any tool that supports window sharing.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Display", systemImage: "display")
                .font(.headline)

            Picker("Display", selection: Binding(
                get: { model.selectedDisplayID ?? 0 },
                set: { model.setSelectedDisplayID($0) }
            )) {
                ForEach(model.displays) { display in
                    Text(display.description).tag(display.id)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            HStack(spacing: 12) {
                Button("Refresh Displays") {
                    model.refreshDisplays()
                }

                if model.hasScreenAccess {
                    Text("Screen access granted")
                        .foregroundStyle(.green)
                } else {
                    Button("Grant Screen Access") {
                        model.requestScreenAccess()
                    }
                }
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var regionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Region", systemImage: "selection.pin.in.out")
                .font(.headline)

            if let selection = model.selection {
                Text("Selected area: \(Int(selection.globalRect.width)) × \(Int(selection.globalRect.height)) points")
                    .foregroundStyle(.secondary)
            } else {
                Text("No region selected yet.")
                    .foregroundStyle(.secondary)
            }

            Button(model.selection == nil ? "Choose Region" : "Retake Region") {
                model.chooseRegion()
            }
            .disabled(model.isChoosingRegion || !model.hasScreenAccess || model.selectedDisplay == nil)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Capture", systemImage: "record.circle")
                .font(.headline)

            HStack(spacing: 12) {
                Button("Open Share Window") {
                    model.showShareWindow()
                }
                .disabled(model.selection == nil)

                Button(model.isSharing ? "Pause Capture" : "Start Capture") {
                    Task {
                        if model.isSharing {
                            await model.stopSharing()
                        } else {
                            try? await model.startSharing()
                        }
                    }
                }
                .disabled(model.selection == nil)
            }

            Text(model.statusMessage)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Live Preview", systemImage: "play.rectangle")
                .font(.headline)

            SharePreviewContentView(recorder: model.recorder)
                .frame(minHeight: 280)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to use it")
                .font(.headline)
            Text("1. Grant screen access.")
            Text("2. Choose the display, then drag directly on the overlay.")
            Text("3. Share the “Share Crop” window in your meeting tool.")
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
    }
}
