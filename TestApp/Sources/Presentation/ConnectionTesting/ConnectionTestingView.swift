import SwiftUI

struct ConnectionTestingView: View {
    @ObservedObject var viewModel: ConnectionTestingViewModel

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

                TextField("https://api.example.com", text: $viewModel.testURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                Text("Use a URL covered by the pinning configuration you set up above.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Button(action: viewModel.runConnectionTest) {
                Text("Test Connection")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((viewModel.isConfigured && !viewModel.isURLEmpty) ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!viewModel.isConfigured || viewModel.isTesting || viewModel.isURLEmpty)

            Button(action: viewModel.runFetchCertificate) {
                Text("Fetch Certificate")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isURLEmpty ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.isTesting || viewModel.isURLEmpty)

            Button(action: viewModel.clearLog) {
                Text("Clear Log")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .foregroundColor(Color.accentColor)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
