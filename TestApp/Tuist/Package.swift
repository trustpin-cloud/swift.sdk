// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "TrustPinKit": .staticFramework,
            "TrustPinAttest": .staticFramework
        ]
    )
#endif

let package = Package(
    name: "TestAppPackages",
    dependencies: [
        .package(name: "TrustPinKit", path: "../../")
    ]
)