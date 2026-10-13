// swift-tools-version:5.9
// Vendored copy of https://github.com/BB9z/LAME-xcframework (tag 3.100.3).
// The only change from upstream is .watchOS(.v4) -> .watchOS(.v9): the older
// declaration triggers a #DeprecatedDeclaration manifest warning with current
// Swift toolchains ("watchOS 9.0 is the oldest supported version").
// If upstream ever ships a fix, delete this package and restore the URL-based
// dependency in the root Package.swift.

import PackageDescription

let package = Package(
    name: "LAME-xcframework",
    platforms: [
        .iOS(.v12),
        .macCatalyst(.v13),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "LAME", targets: ["LAME"])
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "LAME",
            url: "https://github.com/BB9z/LAME-xcframework/releases/download/3.100.3/LAME.xcframework.zip",
            checksum: "bcc33a8311c80993a06d363a29f631d74420cf954be8e8ee9e13450a525944ab"
        )
    ]
)
