// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TrustPinKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
        .macCatalyst(.v15),
        .watchOS(.v9),
        .tvOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "TrustPinKit",
            targets: ["TrustPinKit"]
        ),
        .library(
            name: "TrustPinKitAlamofire",
            targets: ["TrustPinKitAlamofire"]
        ),
        .library(
            name: "TrustPinAttestKit",
            targets: ["TrustPinAttestKit", "TrustPinKit"]
        ),
    ],
    dependencies: [
        // 5.10.0 introduced the `@Sendable` RequestAdapter completion the
        // attestation adapter implements (spec 009); 5.9 cannot compile it.
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0")
    ],
    targets: [
        .binaryTarget(
            name: "TrustPinKit",
            url: "https://github.com/trustpin-cloud/swift.sdk/releases/download/7.0.0/TrustPinKit-7.0.0.xcframework.zip",
            checksum: "ab2b4546da3efdf9d16750074dc9ee97d1e06b68ae69367c892459d73e7b756f"
        ),
        .target(
            name: "TrustPinKitAlamofire",
            dependencies: [
                "TrustPinKit",
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Sources/TrustPinKitAlamofire"
        ),
        .binaryTarget(
            name: "TrustPinAttestKit",
            url: "https://github.com/trustpin-cloud/swift.sdk/releases/download/7.0.0/TrustPinAttestKit-7.0.0.xcframework.zip",
            checksum: "1cce3453e3f77e6c99ff72ff33ab1b94601cb3c446f0c745db21c3ef95779d82"
        )
    ]
)
