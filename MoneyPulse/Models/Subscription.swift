import Foundation

/// A recurring monthly cost such as Netflix or a gym membership.
struct Subscription: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var monthlyCost: Double
    var category: String?

    init(id: UUID = UUID(), name: String, monthlyCost: Double, category: String? = nil) {
        self.id = id
        self.name = name
        self.monthlyCost = monthlyCost
        self.category = category
    }
}
