// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PomodoCat",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "PomodoCat",
            path: "Sources/PomodoCat",
            exclude: ["Resources"]
        )
    ]
)
