import Foundation

/// The only place in the app that talks to UserDefaults.
/// Every model is encoded to JSON and stored under its own key.
final class StorageService {
    private enum Key {
        static let transactions = "moneypulse.transactions"
        static let subscriptions = "moneypulse.subscriptions"
        static let goals = "moneypulse.goals"
        static let contributions = "moneypulse.contributions"
        static let settings = "moneypulse.settings"
        static let hasCompletedOnboarding = "moneypulse.hasCompletedOnboarding"

        static let all = [transactions, subscriptions, goals, contributions, settings, hasCompletedOnboarding]
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Transactions

    func loadTransactions() -> [Transaction] {
        load([Transaction].self, forKey: Key.transactions) ?? []
    }

    func saveTransactions(_ transactions: [Transaction]) {
        save(transactions, forKey: Key.transactions)
    }

    // MARK: - Subscriptions

    func loadSubscriptions() -> [Subscription] {
        load([Subscription].self, forKey: Key.subscriptions) ?? []
    }

    func saveSubscriptions(_ subscriptions: [Subscription]) {
        save(subscriptions, forKey: Key.subscriptions)
    }

    // MARK: - Goals

    func loadGoals() -> [SavingsGoal] {
        load([SavingsGoal].self, forKey: Key.goals) ?? []
    }

    func saveGoals(_ goals: [SavingsGoal]) {
        save(goals, forKey: Key.goals)
    }

    // MARK: - Contributions

    func loadContributions() -> [SavingsContribution] {
        load([SavingsContribution].self, forKey: Key.contributions) ?? []
    }

    func saveContributions(_ contributions: [SavingsContribution]) {
        save(contributions, forKey: Key.contributions)
    }

    // MARK: - Settings

    func loadSettings() -> UserSettings {
        load(UserSettings.self, forKey: Key.settings) ?? .default
    }

    func saveSettings(_ settings: UserSettings) {
        save(settings, forKey: Key.settings)
    }

    // MARK: - Onboarding

    func loadHasCompletedOnboarding() -> Bool {
        defaults.bool(forKey: Key.hasCompletedOnboarding)
    }

    func saveHasCompletedOnboarding(_ value: Bool) {
        defaults.set(value, forKey: Key.hasCompletedOnboarding)
    }

    // MARK: - Reset

    func clearAll() {
        Key.all.forEach { defaults.removeObject(forKey: $0) }
    }

    // MARK: - Generic helpers

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("StorageService: failed to decode \(key): \(error)")
            return nil
        }
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        do {
            defaults.set(try encoder.encode(value), forKey: key)
        } catch {
            print("StorageService: failed to encode \(key): \(error)")
        }
    }
}
