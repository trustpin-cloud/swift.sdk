import SwiftUI

struct LogOutputView: View {
    @ObservedObject var viewModel: LogsViewModel
    var title: String = "Log Output"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Clear", action: viewModel.clear)
                    .font(.subheadline)
                    .disabled(viewModel.logs.isEmpty)
            }

            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.logs) { entry in
                            Text(entry.formattedMessage)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(colorForLogLevel(entry.level))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.samplePanel)
                    .cornerRadius(8)
                    .onChange(of: viewModel.logs.count) { _ in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(height: 300)
        }
        .padding()
        .background(Color.sampleCard)
        .cornerRadius(12)
    }

    private func colorForLogLevel(_ level: LogLevel) -> Color {
        switch level {
        case .error:
            return .red
        case .warning:
            return .orange
        case .success:
            return .green
        case .debug:
            return .purple
        case .info:
            return .primary
        }
    }
}
