// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "XenobladeWallpaper",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .target(
            name: "XenoKit",
            path: "Sources/XenoKit",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "XenobladeWallpaper",
            dependencies: ["XenoKit"],
            path: "Sources/XenobladeWallpaper",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "XenoKitTests",
            dependencies: ["XenoKit"],
            path: "Tests/XenoKitTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
