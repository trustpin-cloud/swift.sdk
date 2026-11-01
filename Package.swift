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
            url: "https://github.com/trustpin-cloud/swift.sdk/releases/download/7.1.0/TrustPinKit-7.1.0.xcframework.zip",
            checksum: "42fc973f6adf65da960cdd84147cc26b78ef18cead4cade4e8ff25798df1e2da"
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
            url: "https://github.com/trustpin-cloud/swift.sdk/releases/download/7.1.0/TrustPinAttestKit-7.1.0.xcframework.zip",
            checksum: "e3251a90413c533388155c31ac5531a6ce2ac686120197aab6f14ab9bbacb1a9"
        )
    ]
)
