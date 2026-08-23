// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "synced_shared_preferences",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "synced-shared-preferences", targets: ["synced_shared_preferences"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "synced_shared_preferences",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
