Pod::Spec.new do |spec|
  spec.name         = "TrustPinKit"
  spec.version      = "7.0.1"
  spec.summary      = "TrustPin iOS SDK for certificate pinning and security"
  spec.description  = <<-DESC
                    TrustPin provides advanced certificate pinning and network security
                    capabilities for iOS applications, ensuring secure communication
                    and protection against man-in-the-middle attacks.
                    DESC

  spec.homepage     = "https://github.com/trustpin-cloud/swift.sdk"
  spec.license      = { :type => "Custom", :text => "TrustPin Binary License Agreement - See https://trustpin.cloud for full terms" }
  spec.author       = { "TrustPin" => "support@trustpin.cloud" }

  spec.ios.deployment_target = "15.0"
  spec.osx.deployment_target = "13.0"
  spec.watchos.deployment_target = "9.0"
  spec.tvos.deployment_target = "15.0"
  spec.visionos.deployment_target = "2.0"

  # :sha256 makes CocoaPods verify the downloaded archive against the
  # fingerprint baked in at release time — a tampered or corrupted
  # download fails `pod install` instead of shipping.
  spec.source       = { :http => "https://github.com/trustpin-cloud/swift.sdk/releases/download/7.0.1/TrustPinKit-7.0.1.xcframework.zip",
                        :sha256 => "e6edcc0ef4c6952bb48fc86fd9964e4d9c3e4a7fc9b424edf673b391033c4753" }
  spec.vendored_frameworks = "TrustPinKit.xcframework"

  # System frameworks linked by the SDK.
  # Foundation, Security and CryptoKit are used on every supported platform.
  spec.frameworks    = "Foundation", "Security", "CryptoKit"
  # UIKit/WatchKit are only used for User-Agent metadata on their respective platforms.
  spec.ios.frameworks      = "UIKit"
  spec.tvos.frameworks     = "UIKit"
  spec.visionos.frameworks = "UIKit"
  spec.watchos.frameworks  = "WatchKit"
  spec.swift_version = "6.2"

  # Metadata for better discoverability
  spec.documentation_url = "https://docs.trustpin.cloud/sdk/swift"
  spec.social_media_url = "https://trustpin.cloud"

  # Module map and other settings
  spec.module_name = "TrustPinKit"
  spec.requires_arc = true
end
