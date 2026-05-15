// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ApiumQuickLookPreview",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ApiumQuickLookShared",
            targets: ["ApiumQuickLookShared"]
        )
    ],
    targets: [
        .target(
            name: "ApiumQuickLookShared",
            path: "Sources/ApiumQuickLookShared"
        ),
        .testTarget(
            name: "ApiumQuickLookSharedTests",
            dependencies: ["ApiumQuickLookShared"],
            path: "Tests/ApiumQuickLookSharedTests"
        )
    ]
)
