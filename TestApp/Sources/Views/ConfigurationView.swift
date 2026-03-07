import SwiftUI
import TrustPinKit

struct ConfigurationView: View {
    @Binding var organizationId: String
    @Binding var projectId: String
    @Binding var publicKey: String
    @Binding var currentMode: TrustPinMode
    let isConfigured: Bool
    let onSetup: () -> Void
    let onToggleMode: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TrustPin Configuration")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ConfigurationField(
                title: "Organization ID",
                placeholder: "Enter your organization ID",
                text: $organizationId
            )
            
            ConfigurationField(
                title: "Project ID",
                placeholder: "Enter your project ID",
                text: $projectId
            )
            
            ConfigurationField(
                title: "Public Key",
                placeholder: "Enter your base64 public key",
                text: $publicKey,
                isMultiline: true
            )
            
            Button(action: onSetup) {
                Text("Setup TrustPin")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            ModeSelectionView(
                currentMode: currentMode,
                isConfigured: isConfigured,
                onToggle: onToggleMode
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ConfigurationField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false
    
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
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
        }
    }
}

struct ModeSelectionView: View {
    let currentMode: TrustPinMode
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
