import SwiftUI

/// Lets the user log an expense, a subscription or a savings contribution.
struct AddView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case expense = "Expense"
        case subscription = "Subscription"
        case savings = "Savings"

        var id: String { rawValue }
    }

    @Binding var mode: Mode

    @State private var confirmationMessage: String?
    @State private var confirmationToken = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Entry type", selection: $mode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                switch mode {
                case .expense:
                    ExpenseForm(onSaved: showConfirmation)
                case .subscription:
                    SubscriptionForm(onSaved: showConfirmation)
                case .savings:
                    SavingsForm(onSaved: showConfirmation)
                }
            }
            .background(AppBackground())
            .navigationTitle("Add")
            .overlay(alignment: .bottom) {
                if let confirmationMessage {
                    ConfirmationBanner(message: confirmationMessage)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    /// Shows a small banner for ~2 seconds.
    private func showConfirmation(_ message: String) {
        confirmationToken += 1
        let token = confirmationToken
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            confirmationMessage = message
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            guard token == confirmationToken else { return }
            withAnimation(.easeOut) {
                confirmationMessage = nil
            }
        }
    }
}

// MARK: - Expense

private struct ExpenseForm: View {
    private enum Field { case amount, description }

    @EnvironmentObject private var viewModel: FinanceViewModel
    let onSaved: (String) -> Void

    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food
    @State private var note = ""
    @State private var date = Date.now
    @State private var savedCount = 0
    @FocusState private var focusedField: Field?

    private var amount: Double? {
        guard let value = CurrencyFormatter.parseAmount(amountText), value > 0 else { return nil }
        return value
    }

    var body: some View {
        Form {
            Section("Amount") {
                MoneyTextField(
                    text: $amountText,
                    currencySymbol: viewModel.settings.currencySymbol,
                    focus: $focusedField,
                    field: .amount,
                    style: .large
                )
            }

            Section("Details") {
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Label(category.displayName, systemImage: category.symbol).tag(category)
                    }
                }
                .pickerStyle(.menu)

                TextField("Description (e.g. Coffee)", text: $note)
                    .focused($focusedField, equals: .description)
                    .submitLabel(.done)

                DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
            }

            Section {
                Button(action: save) {
                    Text("Add Expense")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .foregroundStyle(.black)
                .disabled(amount == nil)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            let recent = viewModel.recentTransactions
            if !recent.isEmpty {
                Section {
                    ForEach(recent) { transaction in
                        TransactionRow(transaction: transaction, amount: viewModel.money(transaction.amount, cents: true))
                    }
                    .onDelete { offsets in
                        offsets.map { recent[$0] }.forEach(viewModel.deleteTransaction)
                    }
                } header: {
                    Text("Recent expenses")
                } footer: {
                    Text("Swipe left to delete an entry.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .sensoryFeedback(.success, trigger: savedCount)
        .toolbar {
            if focusedField != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        guard let amount else { return }
        viewModel.addTransaction(amount: amount, category: category, description: note, date: date)
        onSaved("\(viewModel.money(amount, cents: true)) expense added")
        savedCount += 1
        amountText = ""
        note = ""
        date = .now
        focusedField = nil
    }
}

private struct TransactionRow: View {
    let transaction: Transaction
    let amount: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.category.symbol)
                .font(.subheadline)
                .foregroundStyle(Color.pulseGreen)
                .frame(width: 34, height: 34)
                .background(Color.pulseGreen.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .lineLimit(1)
                Text("\(transaction.category.displayName) · \(transaction.date.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(amount)
                .font(.body.monospacedDigit().weight(.medium))
        }
    }
}

// MARK: - Subscription

private struct SubscriptionForm: View {
    private enum Field { case name, cost, category }

    @EnvironmentObject private var viewModel: FinanceViewModel
    let onSaved: (String) -> Void

    @State private var name = ""
    @State private var costText = ""
    @State private var category = ""
    @FocusState private var focusedField: Field?

    private let suggestions = ["Netflix", "Spotify", "Gym", "Cloud Storage"]

    private var cost: Double? {
        guard let value = CurrencyFormatter.parseAmount(costText), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool {
        cost != nil && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .cost }

                MoneyTextField(
                    "Monthly cost",
                    text: $costText,
                    currencySymbol: viewModel.settings.currencySymbol,
                    focus: $focusedField,
                    field: .cost
                )

                TextField("Category (optional)", text: $category)
                    .focused($focusedField, equals: .category)
            } header: {
                Text("Subscription")
            } footer: {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(suggestion) { name = suggestion }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }
                    .padding(.top, 6)
                }
            }

            Section {
                Button(action: save) {
                    Text("Add Subscription")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .foregroundStyle(.black)
                .disabled(!canSave)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if !viewModel.subscriptions.isEmpty {
                Section {
                    ForEach(viewModel.subscriptions) { subscription in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subscription.name)
                                if let category = subscription.category {
                                    Text(category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("\(viewModel.money(subscription.monthlyCost, cents: true))/mo")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { viewModel.subscriptions[$0] }.forEach(viewModel.deleteSubscription)
                    }
                } header: {
                    Text("Your subscriptions")
                } footer: {
                    Text("\(viewModel.money(viewModel.monthlySubscriptionCost, cents: true)) per month · \(viewModel.money(viewModel.annualSubscriptionCost)) per year")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            if focusedField != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        guard let cost, canSave else { return }
        viewModel.addSubscription(name: name, monthlyCost: cost, category: category)
        onSaved("\(name.trimmingCharacters(in: .whitespaces)) added")
        name = ""
        costText = ""
        category = ""
        focusedField = nil
    }
}

// MARK: - Savings

private struct SavingsForm: View {
    private enum Field { case amount }

    @EnvironmentObject private var viewModel: FinanceViewModel
    let onSaved: (String) -> Void

    @State private var amountText = ""
    @State private var selectedGoalID: UUID?
    @State private var date = Date.now
    @State private var savedCount = 0
    @State private var completedCount = 0
    @FocusState private var focusedField: Field?

    private var amount: Double? {
        guard let value = CurrencyFormatter.parseAmount(amountText), value > 0 else { return nil }
        return value
    }

    private var selectedGoal: SavingsGoal? {
        viewModel.goals.first { $0.id == selectedGoalID }
    }

    var body: some View {
        Group {
            if viewModel.goals.isEmpty {
                ContentUnavailableView(
                    "No savings goals yet",
                    systemImage: "target",
                    description: Text("Create a goal in the Goals tab, then add contributions here.")
                )
            } else {
                form
            }
        }
        .sensoryFeedback(.success, trigger: savedCount)
        .sensoryFeedback(.impact(weight: .heavy), trigger: completedCount)
        .onAppear(perform: selectDefaultGoal)
        .onChange(of: viewModel.goals) { _, _ in selectDefaultGoal() }
    }

    private var form: some View {
        Form {
            Section("Amount") {
                MoneyTextField(
                    text: $amountText,
                    currencySymbol: viewModel.settings.currencySymbol,
                    focus: $focusedField,
                    field: .amount,
                    style: .large
                )
            }

            Section {
                Picker("Savings goal", selection: $selectedGoalID) {
                    ForEach(viewModel.goals) { goal in
                        Text(goal.name).tag(Optional(goal.id))
                    }
                }
                .pickerStyle(.menu)

                DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)

                if let selectedGoal {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(viewModel.money(selectedGoal.currentAmount)) of \(viewModel.money(selectedGoal.targetAmount))")
                                .contentTransition(.numericText())
                            Spacer()
                            Text(selectedGoal.progress.formatted(.percent.precision(.fractionLength(0))))
                                .foregroundStyle(Color.pulseGreen)
                                .contentTransition(.numericText())
                        }
                        .font(.subheadline.monospacedDigit())
                        GoalProgressView(progress: selectedGoal.progress)
                    }
                    .padding(.vertical, 4)
                    .animation(.spring, value: selectedGoal.currentAmount)
                }
            } header: {
                Text("Details")
            }

            Section {
                Button(action: save) {
                    Text("Add Contribution")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .foregroundStyle(.black)
                .disabled(amount == nil || selectedGoal == nil)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            if focusedField != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func selectDefaultGoal() {
        if selectedGoal == nil {
            selectedGoalID = viewModel.goals.first { !$0.isCompleted }?.id ?? viewModel.goals.first?.id
        }
    }

    private func save() {
        guard let amount, let goal = selectedGoal else { return }
        let completedGoal = viewModel.addContribution(amount: amount, goalID: goal.id, date: date)
        if completedGoal {
            completedCount += 1
            onSaved("\(goal.name) complete! 🎉")
        } else {
            savedCount += 1
            onSaved("\(viewModel.money(amount)) added to \(goal.name)")
        }
        amountText = ""
        date = .now
        focusedField = nil
    }
}

// MARK: - Feedback banner

private struct ConfirmationBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Color.pulseGreen)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.1)))
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
    }
}

#Preview {
    let viewModel = FinanceViewModel(storage: StorageService(defaults: UserDefaults(suiteName: "preview")!))
    viewModel.loadDemoData()
    return AddView(mode: .constant(.expense))
        .environmentObject(viewModel)
        .preferredColorScheme(.dark)
}
