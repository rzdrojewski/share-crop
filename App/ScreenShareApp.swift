import AppKit
import SwiftUI

@main
struct ScreenShareApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Screen Share Crop") {
            ContentView(model: model)
                .frame(minWidth: 620, minHeight: 520)
        }
        .defaultSize(width: 720, height: 560)
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
