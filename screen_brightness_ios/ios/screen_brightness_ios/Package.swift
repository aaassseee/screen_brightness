import PackageDescription

let package = Package(
    name: "screen_brightness_ios",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "screen_brightness_ios", targets: ["screen_brightness_ios"])
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