// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "otap-swift",
    platforms: [
        .macOS("14.4"),
        .iOS("17.4")
    ],
    products: [
        .library(
            name: "OTAPSwift",
            targets: ["OTAPSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tsolomko/BitByteData.git", .upToNextMajor(from: "2.0.0"))
    ],
    targets: [
        .target(
            name: "OTAPSwift",
            dependencies: [
                .product(name: "BitByteData", package: "BitByteData")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "OTAPSwiftTests",
            dependencies: [
                "OTAPSwift",
                .product(name: "BitByteData", package: "BitByteData")
            ],
            path: "Tests"
        ),
    ]
)
