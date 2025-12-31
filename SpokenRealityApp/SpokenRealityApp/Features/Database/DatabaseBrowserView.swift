import SwiftUI

struct DatabaseBrowserView: View {
    @State private var tables: [DatabaseTable] = DatabaseTable.sampleTables
    @State private var selectedTable: DatabaseTable?
    @State private var searchText: String = ""
    @State private var showTableDetail: Bool = false

    var filteredTables: [DatabaseTable] {
        if searchText.isEmpty {
            return tables
        }
        return tables.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                if tables.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        // Search bar
                        searchBar

                        // Table list
                        tableList
                    }
                }
            }
            .navigationTitle("Database")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showTableDetail) {
                if let table = selectedTable {
                    TableDetailView(table: table)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
                .font(.system(size: 16))

            TextField("Search tables...", text: $searchText)
                .foregroundColor(.textPrimary)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .padding(Spacing.md)
        .background(Color.bgSecondary)
        .cornerRadius(8)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Table List

    private var tableList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Section header
                Text("Tables")
                    .font(.headline)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)

                // Tables
                ForEach(filteredTables) { table in
                    tableRow(table)
                }
            }
            .padding(.top, Spacing.sm)
        }
    }

    private func tableRow(_ table: DatabaseTable) -> some View {
        Button(action: {
            selectedTable = table
            showTableDetail = true
        }) {
            HStack(spacing: Spacing.md) {
                // Icon
                Image(systemName: "tablecells")
                    .font(.system(size: 20))
                    .foregroundColor(.accentPrimary)
                    .frame(width: 32)

                // Table name and count
                VStack(alignment: .leading, spacing: 2) {
                    Text(table.name)
                        .font(.body)
                        .foregroundColor(.textPrimary)

                    Text("\(table.rowCount) rows")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(Color.bgSecondary)
            .cornerRadius(8)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "cylinder")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary)

            Text("No tables yet")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text("Your database tables will appear here")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
    }
}

#Preview {
    DatabaseBrowserView()
}
