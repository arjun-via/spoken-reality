import SwiftUI

struct SettingsView: View {
    @State private var projectName: String = "My Dashboard"
    @State private var showDeleteConfirmation: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var isExporting: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Project Name Section
                        projectNameSection

                        // Export Section
                        exportSection

                        // Danger Zone
                        dangerZoneSection
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                    }
                    .foregroundColor(.accentPrimary)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Project", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Export & Delete", role: .none) {
                    exportAndDelete()
                }
                Button("Delete", role: .destructive) {
                    deleteProject()
                }
            } message: {
                Text("Delete \(projectName)? This cannot be undone. Export first?")
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(isExporting: $isExporting)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Project Name Section

    private var projectNameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Project Name")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)

            TextField("Project name", text: $projectName)
                .foregroundColor(.textPrimary)
                .padding(Spacing.md)
                .background(Color.bgSecondary)
                .cornerRadius(8)
                .autocapitalization(.words)
                .autocorrectionDisabled()
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Export")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)

            Button(action: {
                exportToGitHub()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export to GitHub")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                }
                .foregroundColor(.textPrimary)
                .padding(Spacing.md)
                .background(Color.bgSecondary)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            Text("Download your project as a standard Git repository")
                .font(.caption)
                .foregroundColor(.textTertiary)
                .padding(.horizontal, Spacing.xs)
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Danger Zone")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.error)
                .textCase(.uppercase)

            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Project")
                    Spacer()
                }
                .foregroundColor(.error)
                .padding(Spacing.md)
                .background(Color.bgSecondary)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            Text("Permanently delete this project and all its data")
                .font(.caption)
                .foregroundColor(.textTertiary)
                .padding(.horizontal, Spacing.xs)
        }
    }

    // MARK: - Actions

    private func saveSettings() {
        // TODO: Save settings to backend
        dismiss()
    }

    private func exportToGitHub() {
        isExporting = true
        showExportSheet = true

        // Simulate export
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
        }
    }

    private func exportAndDelete() {
        exportToGitHub()

        // Wait for export, then delete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            deleteProject()
        }
    }

    private func deleteProject() {
        // TODO: Delete project from backend
        dismiss()
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    @Binding var isExporting: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    if isExporting {
                        // Loading state
                        VStack(spacing: Spacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                                .scaleEffect(1.5)

                            Text("Preparing export...")
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            Text("This may take a moment")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    } else {
                        // Success state
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.success)

                            Text("Export Ready")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)

                            Text("Your project is ready to download")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)

                            // Download button
                            Button(action: {
                                downloadExport()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Download ZIP")
                                }
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.md)
                                .background(Color.accentPrimary)
                                .cornerRadius(8)
                            }
                            .padding(.top, Spacing.md)
                        }
                        .padding(Spacing.lg)
                    }
                }
            }
            .navigationTitle("Export Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func downloadExport() {
        // TODO: Implement actual download
        dismiss()
    }
}

#Preview {
    SettingsView()
}
