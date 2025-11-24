// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HarpoonMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "HarpoonMac",
            targets: ["HarpoonMac"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "HarpoonMac",
            dependencies: [],
            path: "Sources/HarpoonMac"
        )
    ]
)
