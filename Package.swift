// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "Semalot",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .watchOS(.v7),
    ],
    products: [
        .library(
            name: "Semalot",
            targets: ["Semalot"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ptsochantaris/lista", branch: "main"),
    ],
    targets: [
        .target(
            name: "Semalot",
            dependencies: [
                .product(name: "Lista", package: "lista"),
            ]
        ),
        .testTarget(
            name: "SemalotTests",
            dependencies: ["Semalot"]
        ),
    ]
)
