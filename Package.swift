// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Workflows",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "Workflows", targets: ["Workflows"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-clocks", from: "1.0.5"),
    ],
    targets: [
        .target(name: "Workflows"),
        .testTarget(name: "WorkflowsTests", dependencies: [
            .product(name: "Clocks", package: "swift-clocks"),
            "Workflows"
        ]),
    ]
)
