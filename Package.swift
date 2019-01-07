// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ws-thing",
    products: [
        .library(
            name: "ws-thing",
            targets: ["NIOWSTryout"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/websocket.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "NIOWSTryout",
            dependencies: ["WebSocket"]),
        .target(
            name: "NIOWSTryoutExample",
            dependencies: ["NIOWSTryout"]
            ),
    ]
)
