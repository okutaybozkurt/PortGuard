// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PortGuard",
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
            exclude: ["Resources/Info.plist"]
        ),
        .testTarget(
            name: "PortGuardTests",
            dependencies: ["PortGuard"],
            path: "Tests/PortGuardTests"
        )
    ]
)
