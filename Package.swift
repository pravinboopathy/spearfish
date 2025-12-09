// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Spearfish",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Spearfish",
            targets: ["Spearfish"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Spearfish",
            dependencies: []
        )
    ]
)
