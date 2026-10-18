import Foundation

/// Turns the numbers from `FinanceCalculations` into human-readable insight cards.
///
/// Wording rules: only describe what the user has logged, label estimates as estimates,
/// never compare the user to other people and never promise outcomes.
enum InsightBuilder {
    static func build(
        transactions: [Transaction],
        subscriptions: [Subscription],
        goals: [SavingsGoal],
        contributions: [SavingsContribution],
        settings: UserSettings,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Insight] {
        let money = { (amount: Double) in
            CurrencyFormatter.string(from: amount, currency: settings.currency)
        }
        var insights: [Insight] = []

        let week = FinanceCalculations.transactionsInLastSevenDays(transactions, now: now, calendar: calendar)
        let weekTotal = FinanceCalculations.total(of: week)
        let month = FinanceCalculations.transactionsThisMonth(transactions, now: now, calendar: calendar)
        let monthTotal = FinanceCalculations.total(of: month)

        // Spending in the last 7 days
        if !week.isEmpty {
            insights.append(Insight(
                id: "weekly-spending",
                type: .neutral,
                label: "Last 7 days",
                value: money(weekTotal),
                title: "Spent in the last 7 days",
                description: "You logged \(week.count) \(plural(week.count, "purchase")) in the last 7 days.",
                symbol: "calendar",
                priority: 10
            ))
        }

        // Estimated monthly pace
        if !week.isEmpty, let pace = FinanceCalculations.estimatedMonthlySpending(transactions, now: now, calendar: calendar) {
            let available = settings.monthlyIncome - settings.monthlySavingsTarget
            let isAboveAvailable = settings.monthlyIncome > 0 && available > 0 && pace > available
            let description = isAboveAvailable
                ? "Estimate: if your last 7 days set the pace, you'd finish the month around \(money(pace)) — above the \(money(available)) left after your savings target."
                : "Estimate: if your recent spending pace continued, you'd finish the month around \(money(pace))."
            insights.append(Insight(
                id: "monthly-pace",
                type: isAboveAvailable ? .warning : .neutral,
                label: "Estimated pace",
                value: money(pace),
                title: "Estimated monthly pace",
                description: description,
                symbol: "speedometer",
                priority: 20
            ))
        }

        // Small purchases
        let small = FinanceCalculations.smallPurchases(transactions, now: now, calendar: calendar)
        if !small.isEmpty {
            let smallTotal = FinanceCalculations.total(of: small)
            insights.append(Insight(
                id: "small-purchases",
                type: small.count >= 5 ? .warning : .neutral,
                label: "Small purchases",
                value: money(smallTotal),
                title: "Small purchases this week",
                description: "\(small.count) \(plural(small.count, "purchase")) under \(money(FinanceCalculations.smallPurchaseThreshold)) added up to \(money(smallTotal)).",
                symbol: "cup.and.saucer.fill",
                priority: 30
            ))
        }

        // Subscriptions
        if !subscriptions.isEmpty {
            let monthly = FinanceCalculations.monthlySubscriptionCost(subscriptions)
            let annual = FinanceCalculations.annualSubscriptionCost(subscriptions)
            insights.append(Insight(
                id: "subscriptions",
                type: .warning,
                label: "Subscriptions",
                value: "\(money(annual)) / year",
                title: "Going to subscriptions",
                description: "Your \(subscriptions.count) recurring \(plural(subscriptions.count, "service")) currently cost \(CurrencyFormatter.string(from: monthly, currency: settings.currency, showsCents: true)) every month.",
                symbol: "repeat.circle.fill",
                priority: 40
            ))
        }

        // Spending this month
        if !month.isEmpty {
            let monthName = now.formatted(.dateTime.month(.wide))
            insights.append(Insight(
                id: "monthly-spending",
                type: .neutral,
                label: "This month",
                value: money(monthTotal),
                title: "Spent this month",
                description: "Across \(month.count) \(plural(month.count, "transaction")) you've entered in \(monthName).",
                symbol: "chart.bar.fill",
                priority: 50
            ))
        }

        // Biggest category
        if let top = FinanceCalculations.largestSpendingCategory(transactions, now: now, calendar: calendar), monthTotal > 0 {
            let share = (top.amount / monthTotal).formatted(.percent.precision(.fractionLength(0)))
            insights.append(Insight(
                id: "top-category",
                type: .neutral,
                label: "Top category",
                value: money(top.amount),
                title: top.category.displayName,
                description: "Your largest spending category this month — \(share) of what you've logged.",
                symbol: top.category.symbol,
                priority: 60
            ))
        }

        // Spending relative to income
        if monthTotal > 0,
           let ratio = FinanceCalculations.spendingAsPercentageOfIncome(spending: monthTotal, income: settings.monthlyIncome) {
            insights.append(Insight(
                id: "income-share",
                type: ratio >= 0.8 ? .warning : .neutral,
                label: "Income check",
                value: ratio.formatted(.percent.precision(.fractionLength(0))),
                title: "Of monthly income logged as spending",
                description: "You've logged \(money(monthTotal)) against \(money(settings.monthlyIncome)) monthly income. Only expenses you've entered are counted.",
                symbol: "gauge.medium",
                priority: 70
            ))
        }

        // Savings goal progress + remaining amount (first unfinished goal)
        if let goal = goals.first(where: { !$0.isCompleted }) ?? goals.first {
            insights.append(Insight(
                id: "goal-progress",
                type: .positive,
                label: "Savings goal",
                value: goal.progress.formatted(.percent.precision(.fractionLength(0))),
                title: goal.name,
                description: goal.isCompleted
                    ? "You've reached your \(money(goal.targetAmount)) goal. Nice work."
                    : "You've saved \(money(goal.currentAmount)) of your \(money(goal.targetAmount)) goal.",
                symbol: goal.isCompleted ? "checkmark.seal.fill" : "target",
                priority: 80
            ))

            if !goal.isCompleted {
                var description = "Your \(goal.name) is getting closer."
                if settings.monthlySavingsTarget > 0 {
                    let months = Int((goal.remainingAmount / settings.monthlySavingsTarget).rounded(.up))
                    description = "At \(money(settings.monthlySavingsTarget)) a month, that's about \(months) more \(plural(months, "month")) of saving."
                }
                insights.append(Insight(
                    id: "goal-remaining",
                    type: .neutral,
                    label: "Still to go",
                    value: money(goal.remainingAmount),
                    title: "Left to reach your goal",
                    description: description,
                    symbol: "flag.checkered",
                    priority: 90
                ))
            }
        }

        // Last savings contribution
        if let last = contributions.max(by: { $0.date < $1.date }),
           let days = FinanceCalculations.daysSinceLastContribution(contributions, now: now, calendar: calendar) {
            let goalName = goals.first { $0.id == last.goalID }?.name ?? "savings"
            let isToday = days == 0
            var description = isToday
                ? "You added \(money(last.amount)) to your \(goalName) today."
                : "Your last \(goalName) contribution was \(days) \(plural(days, "day")) ago."
            if days >= 14 {
                description += " Even a small amount keeps the momentum going."
            }
            insights.append(Insight(
                id: "last-contribution",
                type: days <= 7 ? .positive : .neutral,
                label: "Savings rhythm",
                value: isToday ? "Today" : "\(days) \(plural(days, "day").uppercased())",
                title: isToday ? "Last contribution" : "Since your last contribution",
                description: description,
                symbol: "clock.arrow.circlepath",
                priority: 100
            ))
        }

        return insights.sorted { $0.priority < $1.priority }
    }

    private static func plural(_ count: Int, _ word: String) -> String {
        count == 1 ? word : word + "s"
    }
}
