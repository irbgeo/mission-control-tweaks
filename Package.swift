// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCTweaks",
    platforms: [
        .macOS(.v15),
    ],
    targets: [
        .target(name: "MCKit"),
        .executableTarget(
            name: "MCTweaks",
            dependencies: ["MCKit"]
        ),
        .testTarget(
            name: "MCKitTests",
            dependencies: ["MCKit"]
        ),
    ]
)
