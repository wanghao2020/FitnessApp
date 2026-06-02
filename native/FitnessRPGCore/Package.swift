// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FitnessRPGCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FitnessRPGCore",
            targets: ["FitnessRPGCore"]
        )
    ],
    targets: [
        .target(
            name: "FitnessRPGCore"
        ),
        .testTarget(
            name: "FitnessRPGCoreTests",
            dependencies: ["FitnessRPGCore"]
        )
    ]
)
