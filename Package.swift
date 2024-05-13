// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenTTDAdminPort",
    platforms: [
        .macOS("14.4"),
        .iOS("17.4")
    ],
    products: [
        .library(
            name: "OpenTTDAdminPort",
            targets: ["OpenTTDAdminPort"]),
    ],
    targets: [
        .target(
            name: "OpenTTDAdminPort",
            path: "Sources"
        ),
        .testTarget(
            name: "OpenTTDAdminPortTests",
            dependencies: ["OpenTTDAdminPort"],
            path: "Tests"
        ),
    ]
)
