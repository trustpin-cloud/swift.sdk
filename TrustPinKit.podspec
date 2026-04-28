Pod::Spec.new do |spec|
  spec.name         = "TrustPinKit"
  spec.version      = "4.1.0"
  spec.summary      = "TrustPin iOS SDK for certificate pinning and security"
  spec.description  = <<-DESC
                    TrustPin provides advanced certificate pinning and network security
                    capabilities for iOS applications, ensuring secure communication
                    and protection against man-in-the-middle attacks.
                    DESC

  spec.homepage     = "https://github.com/trustpin-cloud/swift.sdk"
  spec.license      = { :type => "Custom", :text => "TrustPin Binary License Agreement - See https://trustpin.cloud for full terms" }
  spec.author       = { "TrustPin" => "support@trustpin.cloud" }

  spec.ios.deployment_target = "13.0"
  spec.osx.deployment_target = "13.0"
  spec.watchos.deployment_target = "7.0"
  spec.tvos.deployment_target = "13.0"
  spec.visionos.deployment_target = "2.0"

  spec.source       = { :http => "https://github.com/trustpin-cloud/swift.sdk/releases/download/4.1.0/TrustPinKit-4.1.0.xcframework.zip" }
  spec.vendored_frameworks = "TrustPinKit.xcframework"

  spec.frameworks    = "Foundation", "Security"
  spec.swift_version = "6.1"

  # Metadata for better discoverability
  spec.documentation_url = "https://trustpin-cloud.github.io/swift.sdk/"
  spec.social_media_url = "https://trustpin.cloud"

  # Module map and other settings
  spec.module_name = "TrustPinKit"
  spec.requires_arc = true
end
