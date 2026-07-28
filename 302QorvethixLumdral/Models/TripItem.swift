import Foundation

enum TripItemKind: String, Codable, CaseIterable {
    case packing
    case todo
}

enum TripItemCategory: String, Codable, CaseIterable, Identifiable {
    case clothing = "Clothing"
    case essentials = "Essentials"

    var id: String { rawValue }
}

struct TripItem: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var completed: Bool
    var category: TripItemCategory
    var kind: TripItemKind
    var sortOrder: Int

    init(
        id: String = UUID().uuidString,
        title: String,
        completed: Bool = false,
        category: TripItemCategory,
        kind: TripItemKind,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.completed = completed
        self.category = category
        self.kind = kind
        self.sortOrder = sortOrder
    }
}
