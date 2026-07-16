// swift-tools-version: 6.0
import PackageDescription

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
            swiftSettings: [
                .unsafeFlags(["-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"]),
            ],
            linkerSettings: [
                .unsafeFlags(["-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks", "-framework", "Testing"]),
            ]
        ),
    ]
)
