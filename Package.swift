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
            url: "https://github.com/trustpin-cloud/swift.sdk/releases/download/7.0.1/TrustPinKit-7.0.1.xcframework.zip",
            checksum: "e6edcc0ef4c6952bb48fc86fd9964e4d9c3e4a7fc9b424edf673b391033c4753"
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
            url: "https://github.com/trustpin-cloud/swift.sdk/releases/download/7.0.1/TrustPinAttestKit-7.0.1.xcframework.zip",
            checksum: "01dc5a3884ff1fb085cc674547bb9706fe53e0322b2fbb579facc67a081ef003"
        )
    ]
)
