import SwiftUI

/// Three short steps shown on first launch: welcome → financial setup → first goal.
struct OnboardingView: View {
    private enum Step: Int, CaseIterable {
        case welcome, setup, goal
    }

    private enum Field { case income, savings, goalName, goalTarget, goalCurrent }

    @EnvironmentObject private var viewModel: FinanceViewModel

    @State private var step: Step = .welcome
    @State private var incomeText = ""
    @State private var savingsText = ""
    @State private var currency: AppCurrency = .usd
    @State private var goalName = ""
    @State private var goalTargetText = ""
    @State private var goalCurrentText = ""
    @FocusState private var focusedField: Field?

    var body: some View {
        ZStack {
            AppBackground()
                .onTapGesture { focusedField = nil }

            VStack(spacing: 0) {
                if step != .welcome {
                    topBar
                }

                Group {
                    switch step {
                    case .welcome: welcomeStep
                    case .setup: setupStep
                    case .goal: goalStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .padding(24)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: step)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                focusedField = nil
                step = Step(rawValue: step.rawValue - 1) ?? .welcome
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .foregroundStyle(.primary)
            .accessibilityLabel("Back")

            Spacer()

            HStack(spacing: 6) {
                ForEach(Step.allCases, id: \.self) { item in
                    Capsule()
                        .fill(item.rawValue <= step.rawValue ? Color.pulseGreen : Color.white.opacity(0.15))
                        .frame(width: item == step ? 22 : 8, height: 8)
                }
            }

            Spacer()

            // Decimal pads have no return key, so offer a way to close the keyboard.
            Button("Done") { focusedField = nil }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.pulseGreen)
                .frame(width: 52, height: 36, alignment: .trailing)
                .opacity(focusedField == nil ? 0 : 1)
                .disabled(focusedField == nil)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.pulseGreen.opacity(0.08))
                    .frame(width: 180, height: 180)
                Circle()
                    .fill(Color.pulseGreen.opacity(0.16))
                    .frame(width: 120, height: 120)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(Color.pulseGreen)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 14) {
                Text("Know where your money is going.")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("Money Pulse turns everyday spending into simple financial insights.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 14) {
                Button("Get Started") { step = .setup }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Explore with demo data") {
                    viewModel.startWithDemoData()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Step 2: Financial setup

    private var setupStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            StepHeader(
                title: "Your monthly picture",
                subtitle: "These numbers help put your spending in context. You can change them anytime in Profile."
            )

            VStack(alignment: .leading, spacing: 18) {
                OnboardingField(label: "Currency") {
                    Picker("Currency", selection: $currency) {
                        ForEach(AppCurrency.allCases) { currency in
                            Text(currency.label).tag(currency)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                OnboardingField(label: "Monthly income") {
                    MoneyTextField("3200", text: $incomeText, currencySymbol: currency.symbol, focus: $focusedField, field: .income)
                        .fieldBackground()
                }

                OnboardingField(label: "Monthly savings target") {
                    MoneyTextField("500", text: $savingsText, currencySymbol: currency.symbol, focus: $focusedField, field: .savings)
                        .fieldBackground()
                }
            }

            Spacer()

            Button("Continue") {
                focusedField = nil
                step = .goal
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    // MARK: - Step 3: First goal

    private var goalTarget: Double? {
        guard let value = CurrencyFormatter.parseAmount(goalTargetText), value > 0 else { return nil }
        return value
    }

    private var canCreateGoal: Bool {
        !goalName.trimmingCharacters(in: .whitespaces).isEmpty && goalTarget != nil
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            StepHeader(
                title: "Your first savings goal",
                subtitle: "Give your savings somewhere to go. Money Pulse will track your progress."
            )

            VStack(alignment: .leading, spacing: 18) {
                OnboardingField(label: "Goal name") {
                    TextField("Emergency Fund", text: $goalName)
                        .focused($focusedField, equals: .goalName)
                        .fieldBackground()
                }

                OnboardingField(label: "Target amount") {
                    MoneyTextField("5000", text: $goalTargetText, currencySymbol: currency.symbol, focus: $focusedField, field: .goalTarget)
                        .fieldBackground()
                }

                OnboardingField(label: "Saved so far") {
                    MoneyTextField("1250", text: $goalCurrentText, currencySymbol: currency.symbol, focus: $focusedField, field: .goalCurrent)
                        .fieldBackground()
                }
            }

            Spacer()

            VStack(spacing: 14) {
                Button("Create Goal") { finish(createGoal: true) }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canCreateGoal)

                Button("Skip for now") { finish(createGoal: false) }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Finish

    private func finish(createGoal: Bool) {
        focusedField = nil
        let settings = UserSettings(
            monthlyIncome: CurrencyFormatter.parseAmount(incomeText) ?? 0,
            monthlySavingsTarget: CurrencyFormatter.parseAmount(savingsText) ?? 0,
            currency: currency
        )
        var goal: SavingsGoal?
        if createGoal, let goalTarget {
            goal = SavingsGoal(
                name: goalName.trimmingCharacters(in: .whitespaces),
                targetAmount: goalTarget,
                currentAmount: CurrencyFormatter.parseAmount(goalCurrentText) ?? 0
            )
        }
        viewModel.completeOnboarding(settings: settings, firstGoal: goal)
    }
}

// MARK: - Small building blocks

private struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

private struct OnboardingField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            content
        }
    }
}

private extension View {
    func fieldBackground() -> some View {
        padding(16)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.08))
            }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(FinanceViewModel(storage: StorageService(defaults: UserDefaults(suiteName: "preview")!)))
        .preferredColorScheme(.dark)
}
