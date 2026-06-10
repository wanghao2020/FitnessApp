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
        ),
        .library(
            name: "FitnessRPGPersistence",
            targets: ["FitnessRPGPersistence"]
        )
    ],
    targets: [
        .target(
            name: "FitnessRPGCore"
        ),
        .target(
            name: "FitnessRPGPersistence",
            dependencies: ["FitnessRPGCore"]
        ),
        .testTarget(
            name: "FitnessRPGCoreTests",
            dependencies: ["FitnessRPGCore"]
        ),
        .testTarget(
            name: "FitnessRPGPersistenceTests",
            dependencies: ["FitnessRPGCore", "FitnessRPGPersistence"]
        )
    ]
)
