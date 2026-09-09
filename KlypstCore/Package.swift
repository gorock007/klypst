// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "KlypstCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "KlypstCore", targets: ["KlypstCore"])
    ],
    targets: [
        .target(
            name: "KlypstCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "KlypstCoreTests",
            dependencies: ["KlypstCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
