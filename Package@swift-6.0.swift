// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-workflows",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .macCatalyst(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
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
            "Workflows",
        ]),
    ]
)
