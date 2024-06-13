// swift-tools-version:5.9
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
        .package(url: "https://github.com/kdeda/idd-swiftui.git", "2.1.4" ..< "3.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.10.4")
    ],
    targets: [
        .target(
            name: "IDDAlert",
            dependencies: [
                .product(name: "IDDSwiftUI", package: "idd-swiftui"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "IDDAlertTests",
            dependencies: [
                "IDDAlert",
                .product(name: "IDDSwiftUI", package: "idd-swiftui"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        )
    ]
)
