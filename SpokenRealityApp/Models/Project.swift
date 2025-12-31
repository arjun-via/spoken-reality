import Foundation

struct Project: Identifiable {
    let id: UUID
    var name: String
    var lastEdited: Date
    var thumbnailURL: URL?

    init(id: UUID = UUID(), name: String, lastEdited: Date = Date(), thumbnailURL: URL? = nil) {
        self.id = id
        self.name = name
        self.lastEdited = lastEdited
        self.thumbnailURL = thumbnailURL
    }
}
