import Foundation

/// Pure, reusable arithmetic on the user's data.
/// Every function takes its inputs explicitly (including `now` and `calendar`)
/// so results are predictable and easy to test.
enum FinanceCalculations {
    /// Purchases below this amount count as "small purchases".
    static let smallPurchaseThreshold: Double = 15

    static func total(of transactions: [Transaction]) -> Double {
        transactions.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Time windows

    /// Transactions from the start of the day 6 days ago up to the end of today (7 calendar days).
    static func transactionsInLastSevenDays(
        _ transactions: [Transaction],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Transaction] {
        let startOfToday = calendar.startOfDay(for: now)
        guard
            let start = calendar.date(byAdding: .day, value: -6, to: startOfToday),
            let end = calendar.date(byAdding: .day, value: 1, to: startOfToday)
        else { return [] }
        return transactions.filter { $0.date >= start && $0.date < end }
    }

    /// Transactions in the current calendar month.
    static func transactionsThisMonth(
        _ transactions: [Transaction],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Transaction] {
        transactions.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }

    // MARK: - Spending

    static func weeklySpending(_ transactions: [Transaction], now: Date = .now, calendar: Calendar = .current) -> Double {
        total(of: transactionsInLastSevenDays(transactions, now: now, calendar: calendar))
    }

    static func monthlySpending(_ transactions: [Transaction], now: Date = .now, calendar: Calendar = .current) -> Double {
        total(of: transactionsThisMonth(transactions, now: now, calendar: calendar))
    }

    static func monthlySpendingByCategory(
        _ transactions: [Transaction],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ExpenseCategory: Double] {
        Dictionary(grouping: transactionsThisMonth(transactions, now: now, calendar: calendar), by: \.category)
            .mapValues { total(of: $0) }
    }

    static func largestSpendingCategory(
        _ transactions: [Transaction],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> (category: ExpenseCategory, amount: Double)? {
        monthlySpendingByCategory(transactions, now: now, calendar: calendar)
            .max { $0.value < $1.value }
            .map { (category: $0.key, amount: $0.value) }
    }

    /// Purchases under `smallPurchaseThreshold` in the last 7 days.
    static func smallPurchases(
        _ transactions: [Transaction],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Transaction] {
        transactionsInLastSevenDays(transactions, now: now, calendar: calendar)
            .filter { $0.amount < smallPurchaseThreshold }
    }

    static func smallPurchaseTotal(_ transactions: [Transaction], now: Date = .now, calendar: Calendar = .current) -> Double {
        total(of: smallPurchases(transactions, now: now, calendar: calendar))
    }

    /// A simple estimate of where this month's spending will end up:
    ///
    ///     spent so far this month + (average daily spend over the last 7 days × days left in the month)
    ///
    /// Uses `Calendar` for the real number of days in the current month.
    static func estimatedMonthlySpending(
        _ transactions: [Transaction],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Double? {
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count else { return nil }
        let today = calendar.component(.day, from: now)
        let daysLeft = max(daysInMonth - today, 0)
        let dailyPace = weeklySpending(transactions, now: now, calendar: calendar) / 7
        return monthlySpending(transactions, now: now, calendar: calendar) + dailyPace * Double(daysLeft)
    }

    /// Spending as a fraction of income (0.4 = 40%). `nil` when no income is set.
    static func spendingAsPercentageOfIncome(spending: Double, income: Double) -> Double? {
        guard income > 0 else { return nil }
        return spending / income
    }

    // MARK: - Subscriptions

    static func monthlySubscriptionCost(_ subscriptions: [Subscription]) -> Double {
        subscriptions.reduce(0) { $0 + $1.monthlyCost }
    }

    static func annualSubscriptionCost(_ subscriptions: [Subscription]) -> Double {
        monthlySubscriptionCost(subscriptions) * 12
    }

    // MARK: - Savings

    /// Progress clamped to 0...1.
    static func goalProgress(current: Double, target: Double) -> Double {
        guard target > 0 else { return 0 }
        return min(max(current / target, 0), 1)
    }

    /// Whole calendar days between the most recent contribution and today.
    static func daysSinceLastContribution(
        _ contributions: [SavingsContribution],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int? {
        guard let lastDate = contributions.map(\.date).max() else { return nil }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastDate),
            to: calendar.startOfDay(for: now)
        ).day ?? 0
        return max(days, 0)
    }
}
