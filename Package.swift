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
            targets: ["OneClick", "RMOnboardingSDKWrapper"]
        ),
    ],
    dependencies: [
        // RakutenAnalytics dependency
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
        )

        // Wrapper target - bridges OneClick with RakutenAnalytics
        .target(
            name: "RMOnboardingSDKWrapper",
            dependencies: [
                "OneClick",
                .product(name: "RakutenAnalytics", package: "ios-rakutenanalytics")
            ],
            path: "Sources/RMOnboardingSDKWrapper"
        )
    ]
)
