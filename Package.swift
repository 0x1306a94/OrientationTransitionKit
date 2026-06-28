// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OrientationTransitionKit",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "OrientationTransitionKit",
            targets: ["OrientationTransitionKit"]
        ),
    ],
    targets: [
        .target(
            name: "OrientationTransitionKit",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
        .testTarget(
            name: "OrientationTransitionKitTests",
            dependencies: ["OrientationTransitionKit"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
    ]
)
