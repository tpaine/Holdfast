// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Holdfast",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Holdfast",
            path: "Sources/Holdfast"
        )
    ]
)
