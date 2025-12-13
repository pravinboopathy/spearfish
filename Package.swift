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
            dependencies: [],
            path: ".",
            exclude: ["build", "scripts", "README.md", "CONTRIBUTING.md", "LICENSE", ".gitignore", "Resources/Info.plist", "Resources/Spearfish.entitlements"],
            sources: ["Sources"],
            resources: [
                .process("Resources/AppIcon.svg"),
                .process("Resources/MenuBarIcon.svg")
            ]
        )
    ]
)
