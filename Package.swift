// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Adia",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Adia", targets: ["AdiApp"]),
        .library(name: "AdiCore", targets: ["AdiCore"]),
    ],
    targets: [
        .executableTarget(
            name: "AdiApp",
            dependencies: ["AdiCore"],
            path: "Sources/AdiApp"
        ),
        .target(
            name: "AdiCore",
            dependencies: [],
            path: "Sources/AdiCore"
        ),
        .testTarget(
            name: "AdiTests",
            dependencies: ["AdiCore"],
            path: "Tests/AdiTests"
        ),
    ]
)
