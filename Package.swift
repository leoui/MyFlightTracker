// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlightTracker",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "FlightTracker", targets: ["FlightTracker"]),
    ],
    targets: [
        .executableTarget(
            name: "FlightTracker",
            dependencies: [],
            path: "Sources/FlightTracker",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
