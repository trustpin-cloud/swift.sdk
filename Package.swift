// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TrustPinKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
        .macCatalyst(.v15),
        .watchOS(.v8),
        .tvOS(.v15),
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
            url: "https://github.com/trustpin-cloud/swift.sdk/releases/download/6.0.0/TrustPinKit-6.0.0.xcframework.zip",
            checksum: "1fc41a89f25c65282fa6e628d6602e8ca4069cf47171245ca3aca419a2d5d840"
        )
    ]
)
