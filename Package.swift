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
    targets: [
        .target(
            name: "OTTDAdminKit",
            path: "Sources"
        ),
        .testTarget(
            name: "OTTDAdminKitTests",
            dependencies: ["OTTDAdminKit"],
            path: "Tests"
        ),
    ]
)
