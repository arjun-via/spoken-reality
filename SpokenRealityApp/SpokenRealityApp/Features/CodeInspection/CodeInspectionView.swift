import SwiftUI

// Helper struct for flattened tree display
private struct FlatFileTreeItem: Identifiable {
    let id: String
    let item: FileTreeItem
    let level: Int

    init(item: FileTreeItem, level: Int) {
        self.id = "\(item.id)_\(level)"
        self.item = item
        self.level = level
    }
}

struct CodeInspectionView: View {
    @State private var fileTree: [FileTreeItem] = FileTreeItem.sampleFileTree
    @State private var selectedFile: FileTreeItem?
    @State private var expandedFolders: Set<String> = ["folder_src", "folder_app"]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // File tree (30%)
                    fileTreeView
                        .frame(width: geometry.size.width * 0.35)
                        .background(Color.bgSecondary)

                    Divider()
                        .background(Color.bgTertiary)

                    // Code viewer (70%)
                    codeViewerView
                        .frame(width: geometry.size.width * 0.65)
                        .background(Color.bgPrimary)
                }
            }
            .navigationTitle("Code Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Output")
                        }
                        .foregroundColor(.accentPrimary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: exportCode) {
                        Text("Export")
                            .foregroundColor(.accentPrimary)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - File Tree View

    private var fileTreeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(flattenedFileTree()) { flatItem in
                    fileTreeItemButton(item: flatItem.item, level: flatItem.level)
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    private func fileTreeItemButton(item: FileTreeItem, level: Int) -> some View {
        Button(action: {
            handleItemTap(item)
        }) {
            HStack(spacing: Spacing.xs) {
                // Indentation
                Color.clear
                    .frame(width: CGFloat(level) * 16)

                // Chevron for folders
                if item.isFolder {
                    Image(systemName: expandedFolders.contains(item.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.textTertiary)
                        .frame(width: 12)
                } else {
                    Color.clear.frame(width: 12)
                }

                // Icon
                Image(systemName: item.isFolder ? "folder.fill" : "doc.text.fill")
                    .font(.system(size: 14))
                    .foregroundColor(item.isFolder ? .accentPrimary : .textSecondary)

                // Name
                Text(item.name)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected(item) ? .accentPrimary : .textPrimary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(isSelected(item) ? Color.bgTertiary : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Flatten the file tree for display
    private func flattenedFileTree() -> [FlatFileTreeItem] {
        var result: [FlatFileTreeItem] = []

        func flatten(_ items: [FileTreeItem], level: Int) {
            for item in items {
                result.append(FlatFileTreeItem(item: item, level: level))

                if case .folder(_, let children, _) = item, expandedFolders.contains(item.id) {
                    flatten(children, level: level + 1)
                }
            }
        }

        flatten(fileTree, level: 0)
        return result
    }

    // MARK: - Code Viewer

    private var codeViewerView: some View {
        Group {
            if let selectedFile = selectedFile {
                if case .file(_, let content) = selectedFile {
                    codeContentView(content: content, filename: selectedFile.name)
                } else {
                    emptyCodeView(message: "Select a file to view code")
                }
            } else {
                emptyCodeView(message: "Select a file to view code")
            }
        }
    }

    private func codeContentView(content: String, filename: String) -> some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                // File header
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.accentPrimary)
                    Text(filename)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
                .padding(Spacing.sm)
                .background(Color.bgSecondary)

                // Code content with line numbers
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(Array(content.components(separatedBy: "\n").enumerated()), id: \.offset) { index, _ in
                            Text("\(index + 1)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.textTertiary)
                                .frame(width: 40, alignment: .trailing)
                                .padding(.vertical, 1)
                        }
                    }
                    .padding(.horizontal, Spacing.xs)
                    .background(Color.bgSecondary)

                    // Code
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(content.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                            Text(line.isEmpty ? " " : line)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 1)
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
                }
                .padding(.top, Spacing.sm)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func handleItemTap(_ item: FileTreeItem) {
        if item.isFolder {
            // Toggle folder expansion
            if expandedFolders.contains(item.id) {
                expandedFolders.remove(item.id)
            } else {
                expandedFolders.insert(item.id)
            }
        } else {
            // Select file
            selectedFile = item
        }
    }

    private func isSelected(_ item: FileTreeItem) -> Bool {
        guard let selectedFile = selectedFile else { return false }
        return selectedFile.id == item.id
    }

    private func exportCode() {
        // TODO: Implement export functionality
    }
}

#Preview {
    CodeInspectionView()
}
