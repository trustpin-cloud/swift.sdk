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
            url: "https://github.com/trustpin-cloud/swift.sdk/releases/download/4.1.0/TrustPinKit-4.1.0.xcframework.zip",
            checksum: "256d8ae2e00cfd6dbe8c4e63bb7cc9656b7e6a70369f7e07eabd2bf6a5137166"
        )
    ]
)
