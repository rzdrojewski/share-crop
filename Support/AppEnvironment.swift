import Foundation

enum AppEnvironment {
    static let isSmokeTest = ProcessInfo.processInfo.environment["SCREENSHARE_SMOKE_TEST"] == "1"
    static let smokeOutputPath = ProcessInfo.processInfo.environment["SCREENSHARE_SMOKE_OUTPUT"]
}
