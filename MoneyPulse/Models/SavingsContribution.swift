import Foundation

/// A record of money the user moved into one of their savings goals.
struct SavingsContribution: Identifiable, Codable, Equatable {
    let id: UUID
    let goalID: UUID
    var amount: Double
    var date: Date

    init(id: UUID = UUID(), goalID: UUID, amount: Double, date: Date) {
        self.id = id
        self.goalID = goalID
        self.amount = amount
        self.date = date
    }
}
