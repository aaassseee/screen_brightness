// swift-tools-version: 5.4

import PackageDescription

let package = Package(
    name: "screen_brightness_ios",
    platforms: [
        .iOS("9.0"),
    ],
    products: [
        .library(name: "screen-brightness-ios", targets: ["screen_brightness_ios"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "screen_brightness_ios",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)