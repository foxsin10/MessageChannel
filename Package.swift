// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MessageChannel",
    platforms: [.iOS(.v14), .macOS(.v11), .tvOS(.v14), .watchOS(.v7)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "MessageChannel", targets: ["MessageChannel"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.2"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.2.1"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", from: "0.4.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MessageChannel",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
                .product(name: "CustomDump", package: "swift-custom-dump")
            ],
            swiftSettings: [
                .define("Tracing", .when(platforms: [.iOS, .macOS, .tvOS, .watchOS], configuration: .debug))
            ]
        ),

        .testTarget(
            name: "MessageChannelTests",
            dependencies: ["MessageChannel"]
        ),
    ]
)
