import Foundation
import TrustPinKit

struct TrustPinConfiguration {
    let organizationId: String
    let projectId: String
    let publicKey: String
    let mode: TrustPinMode

    /// Default starting point used by the sample app on first launch.
    ///
    /// In the published `swift.sdk` repository these credentials are blanked out at
    /// release time (see the `trustpin:sample-credential` sed step in
    /// `.github/workflows/deploy-version.yml`) so the app cannot be run end-to-end
    /// against a project the user does not own. End users create a free project at
    /// https://app.trustpin.cloud and paste their own `organizationId`, `projectId`,
    /// and base64 `publicKey` into the configuration screen.
    static let empty = TrustPinConfiguration(
        organizationId: "", // trustpin:sample-credential
        projectId: "", // trustpin:sample-credential
        publicKey: "", // trustpin:sample-credential
        mode: .strict
    )

    var isValid: Bool {
        !organizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !projectId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !publicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
