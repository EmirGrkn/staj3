# Money Pulse

A native SwiftUI personal-finance awareness MVP.

Money Pulse turns everyday spending you log by hand into short, honest insight cards, like *"$126 spent in the last 7 days"* or *"$684/year goes to subscriptions"*. The aim is to help people notice their habits and feel a gentle sense of urgency, without fake benchmarks, guilt, or financial advice.

> Built as an internship/training project. The focus is clean Swift, native iOS patterns and polish, not feature count.

---

## Screenshots

| Pulse | Add | Goals | Profile |
|-------|-----|-------|---------|
| _screenshot_ | _screenshot_ | _screenshot_ | _screenshot_ |

---

## Features

- **Onboarding** (3 steps): welcome screen, financial setup (income, savings target, currency) and an optional first savings goal. The welcome screen also has an **"Explore with demo data"** shortcut.
- **Pulse tab**: a scrolling feed of insight cards generated from your data, sorted by priority:
  - Spending in the last 7 days
  - Estimated monthly pace (clearly labelled as an estimate)
  - Small purchases (under 15) in the last 7 days
  - Subscription cost per year and per month
  - Spending this calendar month
  - Largest spending category this month
  - Logged spending as a share of monthly income
  - Savings goal progress and remaining amount
  - Days since your last savings contribution
- **Add tab**: a segmented picker for **Expense | Subscription | Savings**, with inline validation, haptics and a lightweight confirmation banner. Recent expenses and subscriptions can be swiped to delete.
- **Goals tab**: goal cards with native `ProgressView`. You can create, add money to, edit and delete goals (with a confirmation alert).
- **Profile tab**: edit income, savings target and currency (USD $, EUR €, TRY ₺). You can also reload demo data or clear everything.
- **Empty states** with a clear next action.
- A dark, card-based fintech look built only with native SwiftUI.

---

## Technologies

- Swift 5, **SwiftUI**, iOS 17+
- SF Symbols
- `Codable` + `JSONEncoder` / `JSONDecoder`
- `UserDefaults` for persistence
- Native APIs only: `TabView`, `NavigationStack`, `Form`, `Picker`, `.sheet`, `.alert`, `ContentUnavailableView`, `@FocusState`, `.sensoryFeedback`, `.contentTransition(.numericText())`

No third-party libraries, networking, backend or authentication.

---

## Architecture

The app uses a lightweight MVVM setup with **one** central view model.

```text
MoneyPulse/
├── MoneyPulseApp.swift          App entry; creates the view model (@StateObject)
├── Models/                      Plain Codable structs
│   ├── Transaction.swift        + ExpenseCategory enum
│   ├── Subscription.swift
│   ├── SavingsGoal.swift        + progress / remaining helpers
│   ├── SavingsContribution.swift
│   ├── UserSettings.swift       + AppCurrency enum
│   └── Insight.swift            + InsightType enum
├── ViewModels/
│   └── FinanceViewModel.swift   Single source of truth (@MainActor ObservableObject)
├── Services/
│   └── StorageService.swift     The only code that touches UserDefaults
├── Utilities/
│   ├── FinanceCalculations.swift  Pure arithmetic (weekly/monthly totals, pace…)
│   ├── InsightBuilder.swift       Turns calculations into Insight cards
│   └── CurrencyFormatter.swift    Currency display + input parsing
├── Demo/
│   └── DemoData.swift           Realistic sample data relative to "today"
└── Views/
    ├── RootView.swift           Onboarding vs. TabView
    ├── Onboarding/  Pulse/  Add/  Goals/  Profile/
    └── Components/              Theme, EmptyStateView, MoneyTextField, GoalProgressView
```

**Data flow**

```text
View ──calls──▶ FinanceViewModel.addTransaction(...)
                     │
                     ├─ updates @Published array ──▶ SwiftUI re-renders
                     └─ didSet ──▶ StorageService.saveTransactions(...) ──▶ UserDefaults
```

- `FinanceViewModel` is created once with `@StateObject` and shared through `.environmentObject`. Most screens read it with `@EnvironmentObject`. Sheets receive it explicitly as `@ObservedObject`.
- Views contain **no business calculations**. They call view-model functions and display values.
- `insights` is a computed property on the view model, so the Pulse cards always reflect the latest data.
- Each `Insight` has a stable string `id` (for example `"weekly-spending"`) instead of a random UUID. When a value changes, SwiftUI animates that number instead of rebuilding the card.

---

## Persistence

`StorageService` encodes each collection (transactions, subscriptions, goals, contributions, settings) to JSON and stores it under its own `UserDefaults` key. It also stores a boolean for onboarding completion.

Every `@Published` property in `FinanceViewModel` has a `didSet` that saves it immediately. You don't need to remember to call "save".

UserDefaults is fine for the small amount of data in this MVP. For larger datasets, see future improvements below.

---

## How insights are calculated

Every number is transparent arithmetic on data the user entered. All date logic uses `Calendar`, so the app never assumes a month has 30 days.

| Insight | Formula |
|---|---|
| Last 7 days | Sum of expenses from the start of the day 6 days ago through today |
| This month | Sum of expenses in the current calendar month (`Calendar.isDate(_:equalTo:toGranularity: .month)`) |
| Estimated pace | `spent this month + (last-7-days total ÷ 7) × days left in month`, where the days in the month come from `Calendar.range(of: .day, in: .month)`. Shown as a warning if it exceeds *income − savings target*. |
| Small purchases | Expenses under 15 (in the selected currency) in the last 7 days |
| Subscriptions | Sum of monthly costs, and that sum × 12 for the yearly figure |
| Top category | Expenses this month grouped by category; the largest total wins |
| Income check | Spending this month ÷ monthly income. The wording makes clear that only logged expenses count. |
| Goal progress | `current ÷ target`, clamped to 0–100%, for the first unfinished goal |
| Remaining | `target − current`. If a savings target is set, it also shows how many months that is at the current target. |
| Last contribution | Whole calendar days between the latest contribution and today |

**Content rules:** there are no comparisons to other people, no "you're falling behind", no investment claims and no guaranteed outcomes. Estimates are labelled as estimates, and the Pulse feed ends with a short disclaimer.

---

## How to run

1. Open `MoneyPulse.xcodeproj` in **Xcode 16 or later**.
2. Select the **MoneyPulse** scheme and an iPhone simulator running iOS 17+.
3. Press **⌘R**.
4. On the welcome screen, tap **Get Started** to set up from scratch, or **Explore with demo data** for a fully populated app.

You can reload demo data at any time from **Profile → Reset Demo Data**. **Clear All Data** wipes everything and returns to onboarding.

> Running on a physical device requires choosing your own team under *Signing & Capabilities*.

---

## Limitations

- All data is entered manually, so insights reflect only what the user logs, not their full finances.
- The small-purchase threshold is a fixed 15 in any currency. It isn't adjusted per currency.
- Changing the currency changes only the symbol. Amounts are **not** converted.
- Subscriptions are treated as monthly, and there are no yearly billing cycles.
- UserDefaults isn't meant for large datasets, and there is no sync between devices.
- Contributions can't be edited or deleted individually. Edit the goal's amount instead.

---

## Future improvements

_These are **not** part of the MVP. They are possible next steps._

- **SwiftData** for more scalable local storage and querying
- **Bank integration** to import transactions automatically
- **iCloud** sync across devices
- **Spending charts** (e.g. with Swift Charts)
- **Notification reminders** for savings contributions
- **Automatic recurring expense detection** to suggest subscriptions
