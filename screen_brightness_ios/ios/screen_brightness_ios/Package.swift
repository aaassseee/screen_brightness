// swift-tools-version: 5.4

import PackageDescription

let package = Package(
    name: "screen_brightness_ios",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "screen-brightness-ios", targets: ["screen_brightness_ios"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "screen_brightness_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(
            name: "screen_brightness_ios_tests",
            dependencies: [
                "screen_brightness_ios"
            ]
        )
    ]
)
