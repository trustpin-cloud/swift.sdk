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
        .library(
            name: "TrustPinKitAlamofire",
            targets: ["TrustPinKitAlamofire"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0")
    ],
    targets: [
        .binaryTarget(
            name: "TrustPinKit",
            url: "https://github.com/trustpin-cloud/swift.sdk/releases/download/6.1.0/TrustPinKit-6.1.0.xcframework.zip",
            checksum: "d2080843cccde525ba9379e4135732ddf9acb87ff66c832ddbeaaf83b07cdc48"
        ),
        .target(
            name: "TrustPinKitAlamofire",
            dependencies: [
                "TrustPinKit",
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Sources/TrustPinKitAlamofire"
        )
    ]
)
