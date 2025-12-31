import SwiftUI

struct TableDetailView: View {
    let table: DatabaseTable
    @State private var rows: [DatabaseRow] = []
    @State private var selectedRow: DatabaseRow?
    @State private var showRowDetail: Bool = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Table info header
                tableInfoHeader

                // Column headers
                columnHeaders

                // Rows
                if rows.isEmpty {
                    emptyState
                } else {
                    rowsList
                }
            }
        }
        .navigationTitle(table.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRowDetail) {
            if let row = selectedRow {
                RowDetailView(table: table, row: row)
            }
        }
        .onAppear {
            loadRows()
        }
    }

    // MARK: - Table Info Header

    private var tableInfoHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(rows.count) rows")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Text("\(table.columns.count) columns")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Refresh button
            Button(action: loadRows) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
                    .foregroundColor(.accentPrimary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.bgSecondary)
    }

    // MARK: - Column Headers

    private var columnHeaders: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(table.columns) { column in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(column.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)

                        Text(column.type)
                            .font(.system(size: 10))
                            .foregroundColor(.textTertiary)
                    }
                    .frame(width: 120, alignment: .leading)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                }
            }
            .background(Color.bgSecondary)
        }
        .frame(height: 40)
    }

    // MARK: - Rows List

    private var rowsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    rowView(row)
                        .onTapGesture {
                            selectedRow = row
                            showRowDetail = true
                        }
                }
            }
        }
    }

    private func rowView(_ row: DatabaseRow) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(table.columns) { column in
                    Text(row.values[column.name] ?? "-")
                        .font(.caption)
                        .foregroundColor(.textPrimary)
                        .frame(width: 120, alignment: .leading)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.sm)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
        .frame(height: 40)
        .background(Color.bgPrimary)
        .overlay(
            Rectangle()
                .fill(Color.bgTertiary)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary)

            Text("No data")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text("This table is empty")
                .font(.body)
                .foregroundColor(.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadRows() {
        rows = DatabaseTable.sampleRows(for: table)
    }
}

#Preview {
    NavigationStack {
        TableDetailView(table: DatabaseTable.sampleTables[0])
    }
}
