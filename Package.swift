// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OTTDAdminKit",
    platforms: [
        .macOS("14.4"),
        .iOS("17.4")
    ],
    products: [
        .library(
            name: "OTTDAdminKit",
            targets: ["OTTDAdminKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tsolomko/BitByteData.git", .upToNextMajor(from: "2.0.0"))
    ],
    targets: [
        .target(
            name: "OTTDAdminKit",
            dependencies: [
                .product(name: "BitByteData", package: "BitByteData")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "OTTDAdminKitTests",
            dependencies: [
                "OTTDAdminKit",
                .product(name: "BitByteData", package: "BitByteData")
            ],
            path: "Tests"
        ),
    ]
)
