import SwiftUI

struct CodeInspectionView: View {
    @StateObject private var webSocketService = WebSocketService.shared
    @State private var selectedFile: WebSocketService.GeneratedFile?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // File list (35%)
                    fileListView
                        .frame(width: geometry.size.width * 0.35)
                        .background(Color.bgSecondary)

                    Divider()
                        .background(Color.bgTertiary)

                    // Code viewer (65%)
                    codeViewerView
                        .frame(width: geometry.size.width * 0.65)
                        .background(Color.bgPrimary)
                }
            }
            .navigationTitle("Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.down")
                            Text("Back")
                        }
                        .foregroundColor(.accentPrimary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(webSocketService.generatedFiles.count) files")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Auto-select first file if none selected
            if selectedFile == nil, let first = webSocketService.generatedFiles.first {
                selectedFile = first
            }
        }
    }

    // MARK: - File List View

    private var fileListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if webSocketService.generatedFiles.isEmpty {
                    emptyFilesView
                } else {
                    ForEach(webSocketService.generatedFiles) { file in
                        fileRowButton(file: file)
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    private var emptyFilesView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundColor(.textTertiary)

            Text("No code generated yet")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            Text("Speak a command to generate code")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    private func fileRowButton(file: WebSocketService.GeneratedFile) -> some View {
        Button(action: {
            selectedFile = file
        }) {
            HStack(spacing: Spacing.xs) {
                // File icon
                Image(systemName: iconForFile(file.path))
                    .font(.system(size: 14))
                    .foregroundColor(colorForFile(file.path))

                // File name
                VStack(alignment: .leading, spacing: 2) {
                    Text(fileName(from: file.path))
                        .font(.system(size: 13))
                        .foregroundColor(isSelected(file) ? .accentPrimary : .textPrimary)
                        .lineLimit(1)

                    Text(file.path)
                        .font(.system(size: 10))
                        .foregroundColor(.textTertiary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 8)
            .background(isSelected(file) ? Color.bgTertiary : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Code Viewer

    private var codeViewerView: some View {
        Group {
            if let file = selectedFile {
                codeContentView(content: file.content, filename: file.path)
            } else if webSocketService.generatedFiles.isEmpty {
                emptyCodeView(message: "Generate code to view it here")
            } else {
                emptyCodeView(message: "Select a file to view code")
            }
        }
    }

    private func codeContentView(content: String, filename: String) -> some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    // File header
                    HStack {
                        Image(systemName: iconForFile(filename))
                            .foregroundColor(colorForFile(filename))
                        Text(fileName(from: filename))
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text("\(content.components(separatedBy: "\n").count) lines")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                    }
                    .padding(Spacing.sm)
                    .background(Color.bgSecondary)

                    // Code content with line numbers
                    HStack(alignment: .top, spacing: 0) {
                        // Line numbers
                        VStack(alignment: .trailing, spacing: 0) {
                            ForEach(Array(content.components(separatedBy: "\n").enumerated()), id: \.offset) { index, _ in
                                Text("\(index + 1)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.textTertiary)
                                    .frame(width: 35, alignment: .trailing)
                                    .padding(.vertical, 1)
                            }
                        }
                        .padding(.horizontal, Spacing.xs)
                        .background(Color.bgSecondary)

                        // Code
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(content.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                                Text(line.isEmpty ? " " : line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 1)
                            }
                        }
                        .padding(.horizontal, Spacing.sm)
                    }
                    .padding(.top, Spacing.sm)
                }
                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .topLeading)
            }
        }
    }

    private func emptyCodeView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary)

            Text(message)
                .font(.body)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    // MARK: - Helpers

    private func isSelected(_ file: WebSocketService.GeneratedFile) -> Bool {
        selectedFile?.path == file.path
    }

    private func fileName(from path: String) -> String {
        path.components(separatedBy: "/").last ?? path
    }

    private func iconForFile(_ path: String) -> String {
        let ext = path.components(separatedBy: ".").last?.lowercased() ?? ""
        switch ext {
        case "tsx", "ts": return "swift"
        case "jsx", "js": return "curlybraces"
        case "css", "scss": return "paintbrush"
        case "html": return "chevron.left.forwardslash.chevron.right"
        case "json": return "curlybraces.square"
        case "md": return "doc.richtext"
        default: return "doc.text"
        }
    }

    private func colorForFile(_ path: String) -> Color {
        let ext = path.components(separatedBy: ".").last?.lowercased() ?? ""
        switch ext {
        case "tsx", "ts": return .blue
        case "jsx", "js": return .yellow
        case "css", "scss": return .pink
        case "html": return .orange
        case "json": return .green
        default: return .textSecondary
        }
    }
}

#Preview {
    CodeInspectionView()
}
