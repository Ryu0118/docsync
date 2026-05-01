// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "docsync",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "docsync", targets: ["docsync"]),
        .library(name: "DocSyncKit", targets: ["DocSyncKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "6.0.0"),
        .package(url: "https://github.com/Ryu0118/FileManagerProtocol", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "docsync",
            dependencies: [
                "DocSyncCLI",
            ],
        ),
        .target(
            name: "DocSyncCLI",
            dependencies: [
                "DocSyncKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
        ),
        .target(
            name: "DocSyncKit",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "FileManagerProtocol", package: "FileManagerProtocol"),
            ],
        ),
        .testTarget(
            name: "DocSyncKitTests",
            dependencies: [
                "DocSyncKit",
                .product(name: "Yams", package: "Yams"),
                .product(name: "FileManagerProtocol", package: "FileManagerProtocol"),
            ],
            exclude: [
                "Fixtures",
            ],
        ),
    ],
)
