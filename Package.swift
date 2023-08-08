// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JavascriptBridgeKit",
    platforms: [.iOS(.v11), .macOS(.v11)],
    products: [
        .library(name: "JavascriptBridgeKit", targets: ["JavascriptBridgeKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.6.7"),
    ],
    targets: [
        .target(
            name: "JavascriptBridgeKit",
            dependencies: [
                "JavascriptBridgeCore",
            ],
            path: "Sources/JavascriptBridgeKit/Exports"
        ),
        .target(
            name: "JavascriptBridgeCore",
            dependencies: [
                "AnyCodable",
                "JavascriptBridgeObjC",
            ],
            path: "Sources/JavascriptBridgeKit/Core",
            resources: [
                .process("JSBridge.js"),
            ],
            swiftSettings: [.define("JavascriptBridgeKitModule")]
        ),
        .target(
            name: "JavascriptBridgeObjC",
            dependencies: [],
            path: "Sources/JavascriptBridgeKit/ObjC"
        ),
        .testTarget(
            name: "JavascriptBridgeKitTests",
            dependencies: ["JavascriptBridgeKit"]
        ),
    ]
)
