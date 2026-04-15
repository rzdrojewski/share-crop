// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ScreenShare",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ScreenShare", targets: ["ScreenShare"])
    ],
    targets: [
        .executableTarget(
            name: "ScreenShare",
            path: ".",
            exclude: [
                ".codex",
                ".git",
                "README.md",
                "docs",
                "dist",
                "plans",
                "script"
            ],
            sources: [
                "App",
                "Models",
                "Services",
                "Support",
                "Views"
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreImage"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("ScreenCaptureKit")
            ]
        )
    ]
)
