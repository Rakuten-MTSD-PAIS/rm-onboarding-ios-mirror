// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RMOnboardingSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // The main product that consumers will import
        .library(
            name: "RMOnboardingSDK",
            targets: ["RMOnboardingSDK"]
        ),
    ],
    dependencies: [
        // RakutenAnalytics dependency - compatible with 10.6.0 and above
        .package(
            url: "https://github.com/rakutenanalytics/ios-rakutenanalytics.git",
            from: "10.6.0"
        )
    ],
    targets: [
        // Binary target - the OneClick.xcframework
        // The zip file is included in this repository
        .binaryTarget(
            name: "OneClick",
            path: "OneClick.xcframework.zip"
        ),

        // Main SDK target - bridges OneClick with RakutenAnalytics
        .target(
            name: "RMOnboardingSDK",
            dependencies: [
                "OneClick",
                .product(name: "RakutenAnalytics", package: "ios-rakutenanalytics")
            ],
            path: "Sources/RMOnboardingSDK"
        )
    ]
)
