import SwiftUI
import TrustPinKit

struct ConfigurationView: View {
    @ObservedObject var viewModel: ConfigurationViewModel
    @ObservedObject var session: PinningSession

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TrustPin Configuration")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            DashboardHelpBanner()

            ConfigurationField(
                title: "Organization ID",
                placeholder: "Enter your organization ID",
                text: $viewModel.organizationId,
                isEnabled: !session.isConfigured
            )

            ConfigurationField(
                title: "Project ID",
                placeholder: "Enter your project ID",
                text: $viewModel.projectId,
                isEnabled: !session.isConfigured
            )

            ConfigurationField(
                title: "Public Key",
                placeholder: "Enter your base64 public key",
                text: $viewModel.publicKey,
                isMultiline: true,
                isEnabled: !session.isConfigured
            )

            Button(action: viewModel.setup) {
                Text(session.isConfigured ? "✓ TrustPin Configured" : "Setup TrustPin")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(session.isConfigured ? Color.green : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(session.isConfigured)

            Button(action: viewModel.setupFromBundle) {
                Text("Setup from TrustPin-Info.plist")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                    )
            }
            .disabled(session.isConfigured)

            ModeSelectionView(
                currentMode: viewModel.mode,
                isConfigured: session.isConfigured,
                onToggle: viewModel.toggleModeAlert
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Change Pinning Mode", isPresented: $viewModel.showModeAlert) {
            Button("OK") { }
        } message: {
            Text("To change the pinning mode, modify the 'mode' parameter in the setupTrustPin() function code:\n\n• .strict for production (blocks unregistered domains)\n• .permissive for development (allows unregistered domains)")
        }
    }
}

/// Inline banner pointing the user at the TrustPin dashboard for their credentials.
///
/// The sample ships without working defaults; this gives the user a one-tap path
/// to obtain real credentials instead of leaving the form blank with no context.
struct DashboardHelpBanner: View {
    private static let dashboardURL = URL(string: "https://app.trustpin.cloud")!

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Bring your own credentials")
                .font(.caption)
                .fontWeight(.semibold)
            Text("This sample doesn't ship with a working project. Create one for free at:")
                .font(.caption)
                .foregroundColor(.secondary)
            Link("app.trustpin.cloud", destination: Self.dashboardURL)
                .font(.caption)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
        )
    }
}

struct ConfigurationField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false
    var isEnabled: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            if isMultiline {
                if #available(iOS 16.0, *) {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...5)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .disabled(!isEnabled)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .disabled(!isEnabled)
                }
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .disabled(!isEnabled)
            }
        }
    }
}

struct ModeSelectionView: View {
    let currentMode: PinningMode
    let isConfigured: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pinning Mode")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text(currentMode == .strict ? "Strict Mode" : "Permissive Mode")
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                Toggle("", isOn: .constant(currentMode == .strict))
                    .labelsHidden()
                    .disabled(true)
                    .opacity(0.6)
                    .onTapGesture {
                        onToggle()
                    }
            }

            Text(currentMode == .strict ?
                 "Blocks connections to unregistered domains" :
                 "Allows connections to unregistered domains")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}
