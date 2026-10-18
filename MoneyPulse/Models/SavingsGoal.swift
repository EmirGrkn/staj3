import Foundation

struct SavingsGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double

    init(id: UUID = UUID(), name: String, targetAmount: Double, currentAmount: Double) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
    }

    /// 0.0 ... 1.0
    var progress: Double {
        FinanceCalculations.goalProgress(current: currentAmount, target: targetAmount)
    }

    var remainingAmount: Double {
        max(targetAmount - currentAmount, 0)
    }

    var isCompleted: Bool {
        targetAmount > 0 && currentAmount >= targetAmount
    }
}
