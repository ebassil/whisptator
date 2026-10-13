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
        .package(url: "https://github.com/BB9z/LAME-xcframework.git", from: "3.100.3"),
        .package(url: "https://github.com/microsoft/onnxruntime-swift-package-manager.git", from: "1.16.0"),
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
                .product(name: "ParakeetASR", package: "speech-swift"),
                .product(name: "ParakeetStreamingASR", package: "speech-swift"),
                .product(name: "NemotronStreamingASR", package: "speech-swift"),
                .product(name: "OmnilingualASR", package: "speech-swift"),
                .product(name: "LAME", package: "LAME-xcframework"),
                .product(name: "onnxruntime", package: "onnxruntime-swift-package-manager"),
            ]
        ),
        .testTarget(
            name: "WhisptatorTests",
            dependencies: ["WhisptatorCore"]
        ),
    ]
)
