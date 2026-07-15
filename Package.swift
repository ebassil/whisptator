// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Whisptator",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "WhisptatorCore", targets: ["WhisptatorCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/soniqo/speech-swift", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "Whisptator",
            dependencies: ["WhisptatorCore"]
        ),
        .target(
            name: "WhisptatorCore",
            dependencies: [
                .product(name: "WhisperASR", package: "speech-swift"),
            ]
        ),
        .testTarget(
            name: "WhisptatorTests",
            dependencies: ["WhisptatorCore"]
        ),
    ]
)
