import SwiftUI

struct LogOutputView: View {
    let logs: [LogEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Log Output")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(logs) { entry in
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
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    .onChange(of: logs.count) { _ in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(height: 300)
        }
        .padding()
        .background(Color(.systemGray6))
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