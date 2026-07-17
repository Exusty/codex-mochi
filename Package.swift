// swift-tools-version: 6.0
import Foundation
import PackageDescription

let commandLineToolsFrameworks = "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
let usesCommandLineToolsTesting = FileManager.default.fileExists(
    atPath: "\(commandLineToolsFrameworks)/Testing.framework"
)

let package = Package(
    name: "CodexMochi",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "CodexMochiCore", targets: ["CodexMochiCore"]),
        .executable(name: "CodexMochi", targets: ["CodexMochiApp"]),
    ],
    targets: [
        .target(name: "CodexMochiCore"),
        .executableTarget(name: "CodexMochiApp", dependencies: ["CodexMochiCore"]),
        .testTarget(
            name: "CodexMochiCoreTests",
            dependencies: ["CodexMochiCore"],
            swiftSettings: usesCommandLineToolsTesting
                ? [.unsafeFlags(["-F", commandLineToolsFrameworks])]
                : [],
            linkerSettings: usesCommandLineToolsTesting
                ? [.unsafeFlags(["-F", commandLineToolsFrameworks, "-framework", "Testing"])]
                : []
        ),
    ]
)
