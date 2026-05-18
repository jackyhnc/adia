// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Adia",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "AdiCore", targets: ["AdiCore"]),
        .executable(name: "AdiApp", targets: ["AdiApp"]),
    ],
    targets: [
        .target(
            name: "AdiCore",
            path: "Sources/AdiCore"
        ),
        .executableTarget(
            name: "AdiApp",
            dependencies: ["AdiCore"],
            path: "Sources/AdiApp"
        ),
        .testTarget(
            name: "AdiTests",
            dependencies: ["AdiCore"],
            path: "Tests/AdiTests"
        ),
    ]
)
