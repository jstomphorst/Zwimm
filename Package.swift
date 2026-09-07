// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Zwimm",
    products: [
        .library(name: "Zwimm", targets: ["Zwimm"])
    ],
    targets: [
        .target(
            name: "Zwimm",
            path: "Sources/Zwimm"
        ),
        .testTarget(
            name: "ZwimmTests",
            dependencies: ["Zwimm"],
            path: "Tests/ZwimmTests"
        )
    ]
)
