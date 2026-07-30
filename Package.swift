// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PortGuard",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PortGuard", targets: ["PortGuard"])
    ],
    targets: [
        .executableTarget(
            name: "PortGuard",
            path: "PortGuard",
            exclude: ["Resources/Info.plist", "Resources/AppIcon.icns"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PortGuardTests",
            dependencies: ["PortGuard"],
            path: "Tests/PortGuardTests"
        )
    ]
)
