import SwiftUI

struct RowDetailView: View {
    let table: DatabaseTable
    let row: DatabaseRow
    @Environment(\.dismiss) var dismiss

    @State private var editedValues: [String: String] = [:]
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // Row ID info
                        infoSection

                        // Fields
                        ForEach(table.columns) { column in
                            fieldRow(column: column)
                        }

                        // Actions
                        actionButtons
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Row Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(.accentPrimary)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Row", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteRow()
                }
            } message: {
                Text("Are you sure you want to delete this row? This action cannot be undone.")
            }
        }
        .onAppear {
            editedValues = row.values
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.accentPrimary)

                Text("Editing row in \(table.name)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            if let rowId = row.values["id"] {
                Text("ID: \(rowId)")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgSecondary)
        .cornerRadius(8)
    }

    // MARK: - Field Row

    private func fieldRow(column: DatabaseColumn) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Label
            HStack {
                Text(column.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text(column.type)
                    .font(.system(size: 10))
                    .foregroundColor(.textTertiary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.bgTertiary)
                    .cornerRadius(4)
            }

            // Input field
            TextField(
                "Value",
                text: Binding(
                    get: { editedValues[column.name] ?? "" },
                    set: { editedValues[column.name] = $0 }
                )
            )
            .foregroundColor(.textPrimary)
            .padding(Spacing.sm)
            .background(Color.bgSecondary)
            .cornerRadius(6)
            .autocapitalization(.none)
            .autocorrectionDisabled()
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            Divider()
                .background(Color.bgTertiary)
                .padding(.vertical, Spacing.md)

            // Delete button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Row")
                }
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.error)
                .frame(maxWidth: .infinity)
                .padding(Spacing.md)
                .background(Color.bgSecondary)
                .cornerRadius(8)
            }
        }
        .padding(.top, Spacing.lg)
    }

    // MARK: - Actions

    private func saveChanges() {
        // TODO: Save to backend
        dismiss()
    }

    private func deleteRow() {
        // TODO: Delete from backend
        dismiss()
    }
}

#Preview {
    RowDetailView(
        table: DatabaseTable.sampleTables[0],
        row: DatabaseTable.sampleRows(for: DatabaseTable.sampleTables[0])[0]
    )
}
