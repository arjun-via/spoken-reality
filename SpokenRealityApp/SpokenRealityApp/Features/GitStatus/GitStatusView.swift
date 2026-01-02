import SwiftUI

struct GitStatusView: View {
    @StateObject private var webSocketService = WebSocketService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Branch info
                    branchSection

                    // Changes section (from generated files)
                    changesSection

                    // Session info
                    sessionInfoSection
                }
                .padding(Spacing.md)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Git Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.up")
                            Text("Back")
                        }
                        .foregroundColor(.accentPrimary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    connectionStatus
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Connection Status

    private var connectionStatus: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(webSocketService.connectionState == .connected ? Color.success : Color.error)
                .frame(width: 8, height: 8)
            Text(webSocketService.connectionState == .connected ? "Live" : "Offline")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }

    // MARK: - Branch Section

    private var branchSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Current Branch", systemImage: "arrow.triangle.branch")
                .font(.caption)
                .foregroundColor(.textSecondary)

            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(.accentPrimary)

                Text("main")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                // Files count
                if !webSocketService.generatedFiles.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "doc.badge.plus")
                        Text("\(webSocketService.generatedFiles.count)")
                    }
                    .font(.caption)
                    .foregroundColor(.success)
                }
            }
            .padding(Spacing.md)
            .background(Color.bgSecondary)
            .cornerRadius(12)
        }
    }

    // MARK: - Changes Section

    private var changesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label("Generated Files", systemImage: "doc.badge.plus")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("\(webSocketService.generatedFiles.count) files")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }

            if webSocketService.generatedFiles.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                    Text("No files generated yet")
                        .foregroundColor(.textSecondary)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.bgSecondary)
                .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(webSocketService.generatedFiles) { file in
                        fileChangeRow(file)

                        if file.id != webSocketService.generatedFiles.last?.id {
                            Divider()
                                .background(Color.bgTertiary)
                        }
                    }
                }
                .background(Color.bgSecondary)
                .cornerRadius(12)
            }
        }
    }

    private func fileChangeRow(_ file: WebSocketService.GeneratedFile) -> some View {
        HStack(spacing: Spacing.sm) {
            // Status indicator (A for added/new)
            Text("A")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.success)
                .frame(width: 20)

            // File path
            VStack(alignment: .leading, spacing: 2) {
                Text(fileName(from: file.path))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Text(file.path)
                    .font(.system(size: 10))
                    .foregroundColor(.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            // Lines count
            let lineCount = file.content.components(separatedBy: "\n").count
            Text("+\(lineCount)")
                .font(.caption)
                .foregroundColor(.success)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Session Info

    private var sessionInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Session Info", systemImage: "info.circle")
                .font(.caption)
                .foregroundColor(.textSecondary)

            VStack(spacing: 0) {
                infoRow(label: "Agent State", value: agentStateText)
                Divider().background(Color.bgTertiary)
                infoRow(label: "Last Transcription", value: webSocketService.finalTranscription.isEmpty ? "None" : webSocketService.finalTranscription)
                if let message = webSocketService.agentMessage {
                    Divider().background(Color.bgTertiary)
                    infoRow(label: "Agent Message", value: message)
                }
            }
            .background(Color.bgSecondary)
            .cornerRadius(12)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
        .padding(Spacing.md)
    }

    private var agentStateText: String {
        switch webSocketService.agentState {
        case .idle: return "Ready"
        case .listening: return "Listening..."
        case .interpreting: return "Processing..."
        case .planning: return "Planning..."
        case .executing: return "Building..."
        case .clarifying: return "Needs clarification"
        case .presenting: return "Done"
        case .error: return "Error"
        }
    }

    // MARK: - Helpers

    private func fileName(from path: String) -> String {
        path.components(separatedBy: "/").last ?? path
    }
}

#Preview {
    GitStatusView()
}
