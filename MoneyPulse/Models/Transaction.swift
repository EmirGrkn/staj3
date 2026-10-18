import Foundation

/// A single expense the user logged manually.
struct Transaction: Identifiable, Codable, Equatable {
    let id: UUID
    var amount: Double
    var category: ExpenseCategory
    var description: String
    var date: Date

    init(id: UUID = UUID(), amount: Double, category: ExpenseCategory, description: String, date: Date) {
        self.id = id
        self.amount = amount
        self.category = category
        self.description = description
        self.date = date
    }
}

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food
    case delivery
    case transport
    case shopping
    case entertainment
    case bills
    case health
    case education
    case other

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .food: "fork.knife"
        case .delivery: "takeoutbag.and.cup.and.straw.fill"
        case .transport: "tram.fill"
        case .shopping: "bag.fill"
        case .entertainment: "popcorn.fill"
        case .bills: "doc.text.fill"
        case .health: "cross.case.fill"
        case .education: "book.fill"
        case .other: "square.grid.2x2.fill"
        }
    }
}
