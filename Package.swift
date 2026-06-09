// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

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
        .library(
            name: "ContentDeliveryClient",
            targets: ["ContentDeliveryClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
        .package(url: "https://github.com/WeTransfer/Mocker.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    ],
    targets: [
        .target(
            name: "URLSessionExtension",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ],
        ),
        .macro(
            name: "ContentDeliveryClientMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "ContentDeliveryClient",
            dependencies: [
                "URLSessionExtension",
                "ContentDeliveryClientMacros",
                .product(name: "Logging", package: "swift-log")
            ],
        ),
        .testTarget(
            name: "URLSessionExtensionTests",
            dependencies: [
                "URLSessionExtension",
                .product(name: "Mocker", package: "Mocker")
            ],
        ),
        .testTarget(
            name: "ContentDeliveryClientMacroTests",
            dependencies: [
                "ContentDeliveryClientMacros",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            path: "Tests/ContentDeliveryClientTests",
            sources: ["BlockLibraryMacroTests.swift"]
        ),
        .testTarget(
            name: "ContentDeliveryClientTests",
            dependencies: [
                "ContentDeliveryClient",
                .product(name: "Mocker", package: "Mocker")
            ],
            path: "Tests/ContentDeliveryClientTests",
            sources: ["RelationResolutionTests.swift", "StoryTests.swift", "StoryblokClientTests.swift"]
        ),
        .testTarget(
            name: "Examples",
            dependencies: ["URLSessionExtension"],
            path: "Examples/URLSessionExtension",
        ),
    ]
)
