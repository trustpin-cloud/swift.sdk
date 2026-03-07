import ProjectDescription

let project = Project(
    name: "TestApp",
    targets: [
        .target(
            name: "TestApp",
            destinations: .iOS,
            product: .app,
            bundleId: "cloud.trustpin.TestApp",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen.storyboard",
                    "UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight"
                    ],
                    "UISupportedInterfaceOrientations~ipad": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationPortraitUpsideDown",
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight"
                    ],
                    "NSAppTransportSecurity": [
                        "NSAllowsArbitraryLoads": true,
                        "NSExceptionDomains": [
                            "cdn.trustpin.cloud": [
                                "NSIncludesSubdomains": true,
                                "NSTemporaryExceptionAllowsInsecureHTTPLoads": false,
                                "NSTemporaryExceptionMinimumTLSVersion": "TLSv1.2"
                            ],
                            "api.trustpin.cloud": [
                                "NSIncludesSubdomains": true,
                                "NSTemporaryExceptionAllowsInsecureHTTPLoads": false,
                                "NSTemporaryExceptionMinimumTLSVersion": "TLSv1.2"
                            ]
                        ]
                    ]                 
                ]
            ),
            sources: ["Sources/**"],
            resources: [
                "Sources/Assets.xcassets",
                "Sources/LaunchScreen.storyboard",
                "Sources/trustpin.png"
            ],
            dependencies: [
                .external(name: "TrustPinKit")
            ]
        )
    ]
)
