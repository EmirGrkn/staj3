import SwiftUI

/// Lists savings goals and lets the user create, fund, edit and delete them.
struct GoalsView: View {
    /// Which sheet is currently shown. Using one enum keeps a single `.sheet` modifier.
    private enum ActiveSheet: Identifiable {
        case create
        case edit(SavingsGoal)
        case addMoney(SavingsGoal)

        var id: String {
            switch self {
            case .create: "create"
            case .edit(let goal): "edit-\(goal.id)"
            case .addMoney(let goal): "add-\(goal.id)"
            }
        }
    }

    @EnvironmentObject private var viewModel: FinanceViewModel

    @State private var activeSheet: ActiveSheet?
    @State private var goalPendingDeletion: SavingsGoal?
    @State private var contributionCount = 0
    @State private var completionCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.goals.isEmpty {
                        EmptyStateView(
                            symbol: "target",
                            title: "Give your savings somewhere to go.",
                            message: "Create your first goal and track progress here.",
                            buttonTitle: "Create Goal",
                            action: { activeSheet = .create }
                        )
                    } else {
                        summary

                        ForEach(viewModel.goals) { goal in
                            GoalCard(
                                goal: goal,
                                money: { viewModel.money($0) },
                                onAddMoney: { activeSheet = .addMoney(goal) },
                                onEdit: { activeSheet = .edit(goal) },
                                onDelete: { goalPendingDeletion = goal }
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.goals)
            }
            .background(AppBackground())
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .create
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create Goal")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .create:
                    GoalEditorSheet(viewModel: viewModel, goal: nil)
                case .edit(let goal):
                    GoalEditorSheet(viewModel: viewModel, goal: goal)
                case .addMoney(let goal):
                    AddMoneySheet(viewModel: viewModel, goal: goal) { didComplete in
                        if didComplete {
                            completionCount += 1
                        } else {
                            contributionCount += 1
                        }
                    }
                }
            }
            .alert(
                "Delete goal?",
                isPresented: Binding(
                    get: { goalPendingDeletion != nil },
                    set: { if !$0 { goalPendingDeletion = nil } }
                ),
                presenting: goalPendingDeletion
            ) { goal in
                Button("Delete", role: .destructive) {
                    viewModel.deleteGoal(goal)
                }
                Button("Cancel", role: .cancel) {}
            } message: { goal in
                Text("“\(goal.name)” and its contribution history will be removed.")
            }
            .sensoryFeedback(.success, trigger: contributionCount)
            .sensoryFeedback(.impact(weight: .heavy), trigger: completionCount)
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TOTAL SAVED")
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Text(viewModel.money(viewModel.totalSaved))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            Text("Across \(viewModel.goals.count) \(viewModel.goals.count == 1 ? "goal" : "goals")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

// MARK: - Goal card

private struct GoalCard: View {
    let goal: SavingsGoal
    let money: (Double) -> String
    let onAddMoney: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: goal.isCompleted ? "checkmark.seal.fill" : "target")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.pulseGreen)
                    .frame(width: 34, height: 34)
                    .background(Color.pulseGreen.opacity(0.15), in: Circle())

                Text(goal.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Menu {
                    Button("Add Money", systemImage: "plus.circle", action: onAddMoney)
                    Button("Edit Goal", systemImage: "pencil", action: onEdit)
                    Button("Delete Goal", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Goal options")
            }

            HStack(alignment: .firstTextBaseline) {
                Text(money(goal.currentAmount))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("/ \(money(goal.targetAmount))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(goal.progress.formatted(.percent.precision(.fractionLength(0))))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.pulseGreen)
                    .contentTransition(.numericText())
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            GoalProgressView(progress: goal.progress)

            if goal.isCompleted {
                Label("Goal reached", systemImage: "party.popper.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.pulseGreen)
            } else {
                HStack {
                    Text("\(money(goal.remainingAmount)) to go")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: onAddMoney) {
                        Label("Add Money", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.pulseGreen)
                }
            }
        }
        .cardStyle(tint: .pulseGreen)
    }
}

// MARK: - Create / edit sheet

private struct GoalEditorSheet: View {
    private enum Field { case name, target, current }

    @ObservedObject var viewModel: FinanceViewModel
    let goal: SavingsGoal?

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var targetText: String
    @State private var currentText: String
    @FocusState private var focusedField: Field?

    init(viewModel: FinanceViewModel, goal: SavingsGoal?) {
        self.viewModel = viewModel
        self.goal = goal
        _name = State(initialValue: goal?.name ?? "")
        _targetText = State(initialValue: goal.map { CurrencyFormatter.editingString(from: $0.targetAmount) } ?? "")
        _currentText = State(initialValue: goal.map { CurrencyFormatter.editingString(from: $0.currentAmount) } ?? "")
    }

    private var target: Double? {
        guard let value = CurrencyFormatter.parseAmount(targetText), value > 0 else { return nil }
        return value
    }

    /// Empty "current amount" means 0.
    private var current: Double? {
        currentText.isEmpty ? 0 : CurrencyFormatter.parseAmount(currentText)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && target != nil && current != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name (e.g. Emergency Fund)", text: $name)
                        .focused($focusedField, equals: .name)
                }
                Section {
                    LabeledContent("Target") {
                        MoneyTextField(
                            "5000",
                            text: $targetText,
                            currencySymbol: viewModel.settings.currencySymbol,
                            focus: $focusedField,
                            field: .target,
                            style: .trailing
                        )
                    }
                    LabeledContent("Saved so far") {
                        MoneyTextField(
                            "0",
                            text: $currentText,
                            currencySymbol: viewModel.settings.currencySymbol,
                            focus: $focusedField,
                            field: .current,
                            style: .trailing
                        )
                    }
                } header: {
                    Text("Amounts")
                } footer: {
                    if let target, let current, target > 0 {
                        Text("\(FinanceCalculations.goalProgress(current: current, target: target).formatted(.percent.precision(.fractionLength(0)))) complete")
                    }
                }
            }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(goal == nil ? "Create" : "Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if goal == nil { focusedField = .name }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard let target, let current else { return }
        if var goal {
            goal.name = name.trimmingCharacters(in: .whitespaces)
            goal.targetAmount = target
            goal.currentAmount = current
            viewModel.updateGoal(goal)
        } else {
            viewModel.addGoal(name: name, targetAmount: target, currentAmount: current)
        }
        dismiss()
    }
}

// MARK: - Add money sheet

private struct AddMoneySheet: View {
    private enum Field { case amount }

    @ObservedObject var viewModel: FinanceViewModel
    let goal: SavingsGoal
    /// Reports whether the contribution completed the goal (for haptics in the parent).
    let onAdded: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @FocusState private var focusedField: Field?

    private var amount: Double? {
        guard let value = CurrencyFormatter.parseAmount(amountText), value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    MoneyTextField(
                        text: $amountText,
                        currencySymbol: viewModel.settings.currencySymbol,
                        focus: $focusedField,
                        field: .amount,
                        style: .large
                    )
                } header: {
                    Text("Amount")
                } footer: {
                    Text("\(viewModel.money(goal.remainingAmount)) left to reach \(goal.name).")
                }
            }
            .navigationTitle(goal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: save)
                        .fontWeight(.semibold)
                        .disabled(amount == nil)
                }
            }
            .onAppear { focusedField = .amount }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        guard let amount else { return }
        let didComplete = viewModel.addContribution(amount: amount, goalID: goal.id)
        onAdded(didComplete)
        dismiss()
    }
}

#Preview {
    let viewModel = FinanceViewModel(storage: StorageService(defaults: UserDefaults(suiteName: "preview")!))
    viewModel.loadDemoData()
    return GoalsView()
        .environmentObject(viewModel)
        .preferredColorScheme(.dark)
}
