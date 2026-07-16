// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "plaid_flutter",
    platforms: [
        .iOS("15.0"),
    ],
    products: [
      .library(name: "plaid-flutter", targets: ["plaid_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/plaid/plaid-link-ios-spm.git", exact: "7.0.3")
    ],
    targets: [
        .target(
            name: "plaid_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "LinkKit", package: "plaid-link-ios-spm")
            ],
            path: "Sources/plaid_flutter"
        )
    ]
)
