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
            name: "TrustPinAttest",
            targets: ["TrustPinAttest", "TrustPinKit"]
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
            checksum: "ed26dcb87cde6f05f0691614a9efc41002d09a2dc2d433d0d304627ce73ee6a2"
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
            name: "TrustPinAttest",
            url: "https://github.com/trustpin-cloud/swift.sdk/releases/download/7.0.0/TrustPinAttest-7.0.0.xcframework.zip",
            checksum: "d6d978d164948931611faebff1a3681229c95b634a0863a6af5aa326c1d7c254"
        )
    ]
)
