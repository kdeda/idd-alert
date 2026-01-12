// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idd-alert",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "IDDAlert",
            targets: ["IDDAlert"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kdeda/idd-swift.git", "2.6.6" ..< "3.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.23.1"),
        .package(url: "https://github.com/pointfreeco/swift-navigation.git", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "IDDAlert",
            dependencies: [
                .product(name: "IDDSwift", package: "idd-swift"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SwiftUINavigation", package: "swift-navigation")
            ]
        ),
        .testTarget(
            name: "IDDAlertTests",
            dependencies: [
                "IDDAlert",
                .product(name: "IDDSwift", package: "idd-swift"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SwiftUINavigation", package: "swift-navigation")
            ]
        )
    ]
)
