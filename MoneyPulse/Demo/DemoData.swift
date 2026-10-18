import Foundation

/// Realistic sample data so the app looks alive during a demo.
/// All dates are relative to "now", so weekly and monthly insights always have data.
enum DemoData {
    struct DataSet {
        let transactions: [Transaction]
        let subscriptions: [Subscription]
        let goals: [SavingsGoal]
        let contributions: [SavingsContribution]
        let settings: UserSettings
    }

    static func make(now: Date = .now, calendar: Calendar = .current) -> DataSet {
        /// A date `daysAgo` days back at the given hour (never in the future).
        func date(_ daysAgo: Int, hour: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: now)) ?? now
            let result = calendar.date(byAdding: .hour, value: hour, to: day) ?? day
            return min(result, now)
        }

        let entries: [(daysAgo: Int, hour: Int, amount: Double, category: ExpenseCategory, note: String)] = [
            (0, 8, 4.75, .food, "Morning coffee"),
            (0, 12, 11.90, .food, "Lunch sandwich"),
            (1, 9, 5.20, .food, "Oat latte"),
            (1, 20, 27.80, .delivery, "Sushi delivery"),
            (2, 8, 2.90, .transport, "Metro ticket"),
            (2, 18, 64.35, .food, "Groceries"),
            (3, 12, 13.50, .food, "Burrito bowl"),
            (3, 21, 18.99, .entertainment, "Movie night"),
            (4, 8, 4.75, .food, "Morning coffee"),
            (4, 19, 22.40, .delivery, "Pizza delivery"),
            (5, 8, 2.90, .transport, "Metro ticket"),
            (5, 15, 9.99, .shopping, "Phone case"),
            (6, 10, 6.50, .food, "Bakery"),
            (6, 17, 48.00, .shopping, "Running shorts"),
            (8, 9, 4.75, .food, "Morning coffee"),
            (8, 19, 31.60, .delivery, "Thai delivery"),
            (9, 13, 72.10, .food, "Groceries"),
            (10, 18, 45.00, .bills, "Phone bill"),
            (11, 8, 2.90, .transport, "Metro ticket"),
            (12, 20, 24.00, .entertainment, "Bowling night"),
            (13, 12, 12.25, .food, "Ramen"),
            (14, 18, 59.90, .shopping, "Denim jacket"),
            (15, 9, 5.20, .food, "Oat latte"),
            (16, 19, 26.30, .delivery, "Burger delivery"),
            (17, 14, 18.40, .health, "Pharmacy"),
            (18, 17, 68.45, .food, "Groceries"),
            (19, 8, 2.90, .transport, "Metro ticket"),
            (20, 11, 96.00, .bills, "Electricity"),
            (21, 20, 19.80, .delivery, "Noodle delivery"),
            (22, 13, 14.99, .education, "Design e-book"),
            (23, 9, 4.75, .food, "Morning coffee"),
            (24, 21, 16.50, .entertainment, "Arcade night"),
            (25, 18, 55.20, .food, "Groceries"),
            (26, 12, 42.00, .shopping, "T-shirts"),
            (27, 19, 29.40, .delivery, "Curry delivery"),
            (28, 10, 21.60, .transport, "Ride share"),
            (29, 8, 5.20, .food, "Oat latte"),
        ]

        let transactions = entries
            .map { Transaction(amount: $0.amount, category: $0.category, description: $0.note, date: date($0.daysAgo, hour: $0.hour)) }
            .sorted { $0.date > $1.date }

        let subscriptions = [
            Subscription(name: "Netflix", monthlyCost: 15.49, category: "Entertainment"),
            Subscription(name: "Spotify", monthlyCost: 11.99, category: "Music"),
            Subscription(name: "Gym", monthlyCost: 29.99, category: "Health"),
        ]

        let emergencyFund = SavingsGoal(name: "Emergency Fund", targetAmount: 5_000, currentAmount: 1_850)
        let laptop = SavingsGoal(name: "New Laptop", targetAmount: 1_400, currentAmount: 420)

        let contributions = [
            SavingsContribution(goalID: emergencyFund.id, amount: 400, date: date(54, hour: 10)),
            SavingsContribution(goalID: emergencyFund.id, amount: 300, date: date(33, hour: 10)),
            SavingsContribution(goalID: laptop.id, amount: 120, date: date(30, hour: 18)),
            SavingsContribution(goalID: emergencyFund.id, amount: 250, date: date(19, hour: 10)),
            SavingsContribution(goalID: laptop.id, amount: 100, date: date(16, hour: 18)),
            SavingsContribution(goalID: emergencyFund.id, amount: 200, date: date(11, hour: 10)),
        ]

        return DataSet(
            transactions: transactions,
            subscriptions: subscriptions,
            goals: [emergencyFund, laptop],
            contributions: contributions,
            settings: UserSettings(monthlyIncome: 3_200, monthlySavingsTarget: 500, currency: .usd)
        )
    }
}
