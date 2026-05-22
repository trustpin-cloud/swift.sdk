// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TrustPinKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v13),
        .macCatalyst(.v13),
        .watchOS(.v7),
        .tvOS(.v13),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "TrustPinKit",
            targets: ["TrustPinKit"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "TrustPinKit",
            url: "https://github.com/trustpin-cloud/swift.sdk/releases/download/5.0.0/TrustPinKit-5.0.0.xcframework.zip",
            checksum: "88402a80a5e73bf8b8b49f58d64d07afb95403aad7feeba0c4faf3abd116d7c8"
        )
    ]
)
