import SwiftUI

struct ConnectionTestingView: View {
    @Binding var testURL: String
    let isConfigured: Bool
    let isTesting: Bool
    let statusMessage: String
    let onTest: () -> Void
    let onFetchCertificate: () -> Void
    let onClearLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Connection Testing")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Test URL (GET)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("https://api.example.com", text: $testURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled()
            }

            Button(action: onTest) {
                Text("Test Connection")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isConfigured ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!isConfigured || isTesting)

            Button(action: onFetchCertificate) {
                Text("Fetch Certificate")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isTesting)

            Button(action: onClearLog) {
                Text("Clear Log")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .foregroundColor(Color.accentColor)
                    .cornerRadius(8)
            }

            StatusBadge(message: statusMessage, isConfigured: isConfigured)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatusBadge: View {
    let message: String
    let isConfigured: Bool
    
    var body: some View {
        HStack {
            Text("Status: \(message)")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isConfigured ? Color.accentColor : Color.red)
                .foregroundColor(.white)
                .cornerRadius(6)
            Spacer()
        }
    }
}
