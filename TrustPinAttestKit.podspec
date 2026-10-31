Pod::Spec.new do |spec|
  spec.name         = "TrustPinAttestKit"
  spec.version      = "7.0.1"
  spec.summary      = "TrustPin app attestation for Apple platforms (App Attest)"
  spec.description  = <<-DESC
                    TrustPinAttestKit proves to your backend that requests come from
                    your genuine app on a genuine Apple device: it attests App Attest
                    keys with your verifier, renews short-lived tokens and adds them to
                    the requests you configure. Requires TrustPinKit at the same version.
                    DESC

  spec.homepage     = "https://github.com/trustpin-cloud/swift.sdk"
  spec.license      = { :type => "Custom", :text => "TrustPin Binary License Agreement - See https://trustpin.cloud for full terms" }
  spec.author       = { "TrustPin" => "support@trustpin.cloud" }

  spec.ios.deployment_target = "15.0"
  spec.osx.deployment_target = "13.0"
  spec.watchos.deployment_target = "9.0"
  spec.tvos.deployment_target = "15.0"
  spec.visionos.deployment_target = "2.0"

  spec.source       = { :http => "https://github.com/trustpin-cloud/swift.sdk/releases/download/7.0.1/TrustPinAttestKit-7.0.1.xcframework.zip",
                        :sha256 => "01dc5a3884ff1fb085cc674547bb9706fe53e0322b2fbb579facc67a081ef003" }
  spec.vendored_frameworks = "TrustPinAttestKit.xcframework"

  # The two binaries always ship at the same version (spec 008).
  spec.dependency "TrustPinKit", "= 7.0.1"

  # System frameworks linked by the framework.
  spec.frameworks    = "Foundation", "Security", "CryptoKit", "DeviceCheck"
  spec.swift_version = "6.2"

  spec.documentation_url = "https://docs.trustpin.cloud/sdk/swift"
  spec.social_media_url = "https://trustpin.cloud"

  spec.module_name = "TrustPinAttestKit"
  spec.requires_arc = true
end
