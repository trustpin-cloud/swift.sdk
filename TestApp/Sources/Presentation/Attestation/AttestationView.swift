import SwiftUI

/// Attestation card: state, token expiry, a protected call to the sample API
/// and `reset()`. The device sign-off screen for every Apple platform
/// (spec 008, T25a / verifier PLAN X1b).
struct AttestationView: View {
    @ObservedObject var viewModel: AttestationViewModel
    @ObservedObject var session: PinningSession

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("App Attestation")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.status.isReady ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text(viewModel.status.label)
                    .font(.subheadline)
                Spacer()
            }

            if let outcome = viewModel.lastOutcome {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last protected call: HTTP \(outcome.statusCode)")
                        .font(.caption)
                    Text(outcome.headerAttached ? "Header attached" : "No header attached")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if let summary = outcome.attestationSummary {
                        Text("Verified: \(summary)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Button(action: viewModel.setUp) {
                Text("Set Up Attestation")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canSetUp ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!viewModel.canSetUp)

            Button(action: viewModel.callProtectedEndpoint) {
                Text("Call Protected Endpoint")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canCall ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!viewModel.canCall)

            Button(action: viewModel.signOut) {
                Text("Sign Out (New Session)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canCall ? Color.accentColor.opacity(0.75) : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!viewModel.canCall)

            Button(action: viewModel.reset) {
                Text("Reset Attestation")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canCall ? Color.red.opacity(0.85) : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!viewModel.canCall)

            Text(footnote)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.sampleCard)
        .cornerRadius(12)
    }

    private var footnote: String {
        if session.isConfigured {
            return "Requires the App Attest entitlement and the sample verifier policy; "
                + "on simulators set TRUSTPIN_DEBUG_TOKEN in the scheme."
        }
        return "Configure pinning first: verifier calls are pinned by the TrustPin instance."
    }
}
