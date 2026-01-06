// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Storyblok",
    platforms: [
       .macOS(.v13),
       .iOS(.v16),
       .tvOS(.v16),
       .watchOS(.v9)
    ],

    products: [
        .library(
            name: "URLSessionExtension",
            targets: ["URLSessionExtension"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
        .package(url: "https://github.com/WeTransfer/Mocker.git", .upToNextMajor(from: "3.0.0"))
    ],
    targets: [
        .target(
            name: "URLSessionExtension",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ],
            path: "URLSessionExtension/Sources"
        ),
        .testTarget(
            name: "URLSessionExtensionTests",
            dependencies: [
                "URLSessionExtension",
                .product(name: "Mocker", package: "Mocker")
            ],
            path: "URLSessionExtension/Tests"
        ),
        .testTarget(
            name: "Examples",
            dependencies: ["URLSessionExtension"],
            path: "URLSessionExtension/Examples",
        ),
    ]
)
