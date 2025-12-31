import Foundation

// MARK: - Database Table Model

struct DatabaseTable: Identifiable, Hashable {
    let id: String
    let name: String
    let rowCount: Int
    let columns: [DatabaseColumn]

    init(id: String = UUID().uuidString, name: String, rowCount: Int, columns: [DatabaseColumn]) {
        self.id = id
        self.name = name
        self.rowCount = rowCount
        self.columns = columns
    }
}

// MARK: - Database Column Model

struct DatabaseColumn: Identifiable, Hashable {
    let id: String
    let name: String
    let type: String

    init(id: String = UUID().uuidString, name: String, type: String) {
        self.id = id
        self.name = name
        self.type = type
    }
}

// MARK: - Database Row Model

struct DatabaseRow: Identifiable {
    let id: String
    let values: [String: String] // column name -> value

    init(id: String = UUID().uuidString, values: [String: String]) {
        self.id = id
        self.values = values
    }
}

// MARK: - Sample Data

extension DatabaseTable {
    static let sampleTables: [DatabaseTable] = [
        DatabaseTable(
            name: "Users",
            rowCount: 45,
            columns: [
                DatabaseColumn(name: "id", type: "INTEGER"),
                DatabaseColumn(name: "email", type: "TEXT"),
                DatabaseColumn(name: "name", type: "TEXT"),
                DatabaseColumn(name: "created_at", type: "TIMESTAMP")
            ]
        ),
        DatabaseTable(
            name: "Products",
            rowCount: 128,
            columns: [
                DatabaseColumn(name: "id", type: "INTEGER"),
                DatabaseColumn(name: "name", type: "TEXT"),
                DatabaseColumn(name: "price", type: "DECIMAL"),
                DatabaseColumn(name: "stock", type: "INTEGER")
            ]
        ),
        DatabaseTable(
            name: "Orders",
            rowCount: 89,
            columns: [
                DatabaseColumn(name: "id", type: "INTEGER"),
                DatabaseColumn(name: "user_id", type: "INTEGER"),
                DatabaseColumn(name: "total", type: "DECIMAL"),
                DatabaseColumn(name: "status", type: "TEXT")
            ]
        ),
        DatabaseTable(
            name: "Categories",
            rowCount: 12,
            columns: [
                DatabaseColumn(name: "id", type: "INTEGER"),
                DatabaseColumn(name: "name", type: "TEXT"),
                DatabaseColumn(name: "description", type: "TEXT")
            ]
        )
    ]

    static func sampleRows(for table: DatabaseTable) -> [DatabaseRow] {
        switch table.name {
        case "Users":
            return [
                DatabaseRow(values: ["id": "1", "email": "john@example.com", "name": "John Doe", "created_at": "2024-01-15"]),
                DatabaseRow(values: ["id": "2", "email": "jane@example.com", "name": "Jane Smith", "created_at": "2024-01-16"]),
                DatabaseRow(values: ["id": "3", "email": "bob@example.com", "name": "Bob Johnson", "created_at": "2024-01-17"]),
                DatabaseRow(values: ["id": "4", "email": "alice@example.com", "name": "Alice Brown", "created_at": "2024-01-18"]),
                DatabaseRow(values: ["id": "5", "email": "charlie@example.com", "name": "Charlie Wilson", "created_at": "2024-01-19"])
            ]
        case "Products":
            return [
                DatabaseRow(values: ["id": "1", "name": "Widget", "price": "$29.99", "stock": "150"]),
                DatabaseRow(values: ["id": "2", "name": "Gadget", "price": "$49.99", "stock": "75"]),
                DatabaseRow(values: ["id": "3", "name": "Tool", "price": "$19.99", "stock": "200"]),
                DatabaseRow(values: ["id": "4", "name": "Device", "price": "$99.99", "stock": "50"]),
                DatabaseRow(values: ["id": "5", "name": "Accessory", "price": "$14.99", "stock": "300"])
            ]
        case "Orders":
            return [
                DatabaseRow(values: ["id": "1", "user_id": "1", "total": "$129.99", "status": "completed"]),
                DatabaseRow(values: ["id": "2", "user_id": "2", "total": "$49.99", "status": "pending"]),
                DatabaseRow(values: ["id": "3", "user_id": "1", "total": "$89.99", "status": "shipped"]),
                DatabaseRow(values: ["id": "4", "user_id": "3", "total": "$199.99", "status": "completed"]),
                DatabaseRow(values: ["id": "5", "user_id": "2", "total": "$29.99", "status": "cancelled"])
            ]
        case "Categories":
            return [
                DatabaseRow(values: ["id": "1", "name": "Electronics", "description": "Electronic devices"]),
                DatabaseRow(values: ["id": "2", "name": "Tools", "description": "Hardware tools"]),
                DatabaseRow(values: ["id": "3", "name": "Accessories", "description": "Product accessories"]),
                DatabaseRow(values: ["id": "4", "name": "Software", "description": "Digital products"])
            ]
        default:
            return []
        }
    }
}
