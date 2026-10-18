import Foundation

/// Central state container for the app.
///
/// Views read the published properties and call the functions below to change data.
/// Every change is saved immediately through `StorageService` (see the `didSet`s).
@MainActor
final class FinanceViewModel: ObservableObject {
    @Published var transactions: [Transaction] {
        didSet { storage.saveTransactions(transactions) }
    }
    @Published var subscriptions: [Subscription] {
        didSet { storage.saveSubscriptions(subscriptions) }
    }
    @Published var goals: [SavingsGoal] {
        didSet { storage.saveGoals(goals) }
    }
    @Published var contributions: [SavingsContribution] {
        didSet { storage.saveContributions(contributions) }
    }
    @Published var settings: UserSettings {
        didSet { storage.saveSettings(settings) }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { storage.saveHasCompletedOnboarding(hasCompletedOnboarding) }
    }

    private let storage: StorageService

    init(storage: StorageService = StorageService()) {
        self.storage = storage
        transactions = storage.loadTransactions()
        subscriptions = storage.loadSubscriptions()
        goals = storage.loadGoals()
        contributions = storage.loadContributions()
        settings = storage.loadSettings()
        hasCompletedOnboarding = storage.loadHasCompletedOnboarding()
    }

    // MARK: - Derived data

    /// Insight cards for the Pulse tab, regenerated whenever data changes.
    var insights: [Insight] {
        InsightBuilder.build(
            transactions: transactions,
            subscriptions: subscriptions,
            goals: goals,
            contributions: contributions,
            settings: settings
        )
    }

    var recentTransactions: [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(8))
    }

    var monthlySubscriptionCost: Double {
        FinanceCalculations.monthlySubscriptionCost(subscriptions)
    }

    var annualSubscriptionCost: Double {
        FinanceCalculations.annualSubscriptionCost(subscriptions)
    }

    var totalSaved: Double {
        goals.reduce(0) { $0 + $1.currentAmount }
    }

    /// Formats an amount in the user's selected currency.
    func money(_ amount: Double, cents: Bool = false) -> String {
        CurrencyFormatter.string(from: amount, currency: settings.currency, showsCents: cents)
    }

    // MARK: - Transactions

    func addTransaction(amount: Double, category: ExpenseCategory, description: String, date: Date) {
        guard amount > 0 else { return }
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let transaction = Transaction(
            amount: amount,
            category: category,
            description: trimmed.isEmpty ? category.displayName : trimmed,
            date: date
        )
        transactions = (transactions + [transaction]).sorted { $0.date > $1.date }
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
    }

    // MARK: - Subscriptions

    func addSubscription(name: String, monthlyCost: Double, category: String?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, monthlyCost > 0 else { return }
        let trimmedCategory = category?.trimmingCharacters(in: .whitespacesAndNewlines)
        subscriptions.append(
            Subscription(
                name: trimmedName,
                monthlyCost: monthlyCost,
                category: (trimmedCategory?.isEmpty ?? true) ? nil : trimmedCategory
            )
        )
    }

    func deleteSubscription(_ subscription: Subscription) {
        subscriptions.removeAll { $0.id == subscription.id }
    }

    // MARK: - Goals

    func addGoal(name: String, targetAmount: Double, currentAmount: Double) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, targetAmount > 0 else { return }
        goals.append(SavingsGoal(name: trimmed, targetAmount: targetAmount, currentAmount: max(currentAmount, 0)))
    }

    func updateGoal(_ goal: SavingsGoal) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[index] = goal
    }

    /// Deletes the goal and its contribution history.
    func deleteGoal(_ goal: SavingsGoal) {
        goals.removeAll { $0.id == goal.id }
        contributions.removeAll { $0.goalID == goal.id }
    }

    /// Adds money to a goal and records the contribution.
    /// - Returns: `true` if this contribution completed the goal (used for celebration feedback).
    @discardableResult
    func addContribution(amount: Double, goalID: UUID, date: Date = .now) -> Bool {
        guard amount > 0, let index = goals.firstIndex(where: { $0.id == goalID }) else { return false }
        let wasCompleted = goals[index].isCompleted
        goals[index].currentAmount += amount
        contributions.append(SavingsContribution(goalID: goalID, amount: amount, date: date))
        return !wasCompleted && goals[index].isCompleted
    }

    // MARK: - Onboarding

    func completeOnboarding(settings newSettings: UserSettings, firstGoal: SavingsGoal?) {
        settings = newSettings
        if let firstGoal {
            goals.append(firstGoal)
        }
        hasCompletedOnboarding = true
    }

    /// Skips onboarding and fills the app with sample data (handy for presentations).
    func startWithDemoData() {
        loadDemoData()
        hasCompletedOnboarding = true
    }

    // MARK: - Data management

    func loadDemoData() {
        let demo = DemoData.make()
        transactions = demo.transactions
        subscriptions = demo.subscriptions
        goals = demo.goals
        contributions = demo.contributions
        settings = demo.settings
    }

    /// Removes everything and sends the user back to onboarding.
    func clearAllData() {
        storage.clearAll()
        transactions = []
        subscriptions = []
        goals = []
        contributions = []
        settings = .default
        hasCompletedOnboarding = false
    }
}
