Pod::Spec.new do |spec|
  spec.name         = "TrustPinKit"
  spec.version      = "6.3.0"
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
  spec.watchos.deployment_target = "8.0"
  spec.tvos.deployment_target = "15.0"
  spec.visionos.deployment_target = "2.0"

  # :sha256 makes CocoaPods verify the downloaded archive against the
  # fingerprint baked in at release time — a tampered or corrupted
  # download fails `pod install` instead of shipping.
  spec.source       = { :http => "https://github.com/trustpin-cloud/swift.sdk/releases/download/6.3.0/TrustPinKit-6.3.0.xcframework.zip",
                        :sha256 => "39a2a525a3e3b0f5f58e2988cc60fa29a9564fa32b664479fef7bbd059650a8c" }
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
  spec.documentation_url = "https://trustpin-cloud.github.io/swift.sdk/"
  spec.social_media_url = "https://trustpin.cloud"

  # Module map and other settings
  spec.module_name = "TrustPinKit"
  spec.requires_arc = true
end
