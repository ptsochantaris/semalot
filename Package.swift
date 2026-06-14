// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Semalot",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "Semalot",
            targets: ["Semalot"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ptsochantaris/lista", branch: "main")
    ],
    targets: [
        .target(
            name: "Semalot",
            dependencies: [
                .product(name: "Lista", package: "lista")
            ]
        ),
        .testTarget(
            name: "SemalotTests",
            dependencies: ["Semalot"]
        )
    ]
)
