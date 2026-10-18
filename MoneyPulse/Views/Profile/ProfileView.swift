import SwiftUI

/// Financial settings and data management.
struct ProfileView: View {
    private enum Field { case income, savingsTarget }

    @EnvironmentObject private var viewModel: FinanceViewModel

    @State private var incomeText = ""
    @State private var savingsTargetText = ""
    @State private var showResetDemoAlert = false
    @State private var showClearAlert = false
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.pulseGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your Money Pulse")
                                .font(.headline)
                            Text("All data stays on this device.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    LabeledContent("Monthly income") {
                        MoneyTextField(
                            text: $incomeText,
                            currencySymbol: viewModel.settings.currencySymbol,
                            focus: $focusedField,
                            field: .income,
                            style: .trailing
                        )
                    }
                    LabeledContent("Savings target") {
                        MoneyTextField(
                            text: $savingsTargetText,
                            currencySymbol: viewModel.settings.currencySymbol,
                            focus: $focusedField,
                            field: .savingsTarget,
                            style: .trailing
                        )
                    }
                    Picker("Currency", selection: $viewModel.settings.currency) {
                        ForEach(AppCurrency.allCases) { currency in
                            Text(currency.label).tag(currency)
                        }
                    }
                } header: {
                    Text("Financial settings")
                } footer: {
                    Text("Used to put your logged spending and savings in context on the Pulse tab.")
                }

                Section("Data") {
                    Button {
                        showResetDemoAlert = true
                    } label: {
                        Label("Reset Demo Data", systemImage: "arrow.counterclockwise")
                    }

                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("Money Pulse only uses what you enter. Estimates are simple arithmetic based on your entries and are not financial advice.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Profile")
            .toolbar {
                if focusedField != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { focusedField = nil }
                            .fontWeight(.semibold)
                    }
                }
            }
            .onAppear(perform: loadFields)
            // Save when the user leaves a field (not on every keystroke,
            // which would re-render the whole app while typing).
            .onChange(of: focusedField) { _, _ in saveFields() }
            .onDisappear(perform: saveFields)
            .alert("Load demo data?", isPresented: $showResetDemoAlert) {
                Button("Load Demo Data") {
                    viewModel.loadDemoData()
                    loadFields()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your current expenses, subscriptions, goals and settings will be replaced with sample data.")
            }
            .alert("Clear all data?", isPresented: $showClearAlert) {
                Button("Clear Everything", role: .destructive) {
                    viewModel.clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes everything you've entered and returns you to the welcome screen.")
            }
        }
    }

    /// Copies stored settings into the text fields.
    private func loadFields() {
        incomeText = CurrencyFormatter.editingString(from: viewModel.settings.monthlyIncome)
        savingsTargetText = CurrencyFormatter.editingString(from: viewModel.settings.monthlySavingsTarget)
    }

    /// Writes valid field values back to the view model (which persists them).
    private func saveFields() {
        if let income = parsedSetting(incomeText), income != viewModel.settings.monthlyIncome {
            viewModel.settings.monthlyIncome = income
        }
        if let target = parsedSetting(savingsTargetText), target != viewModel.settings.monthlySavingsTarget {
            viewModel.settings.monthlySavingsTarget = target
        }
    }

    /// Empty text counts as 0 so the user can clear a field.
    private func parsedSetting(_ text: String) -> Double? {
        text.isEmpty ? 0 : CurrencyFormatter.parseAmount(text)
    }
}

#Preview {
    let viewModel = FinanceViewModel(storage: StorageService(defaults: UserDefaults(suiteName: "preview")!))
    viewModel.loadDemoData()
    return ProfileView()
        .environmentObject(viewModel)
        .preferredColorScheme(.dark)
}
