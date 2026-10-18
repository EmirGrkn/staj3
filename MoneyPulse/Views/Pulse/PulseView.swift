import SwiftUI

/// The main screen: a scrolling feed of insight cards generated from the user's data.
struct PulseView: View {
    @EnvironmentObject private var viewModel: FinanceViewModel
    /// Called by the empty state's "Add Expense" button (switches to the Add tab).
    var onAddExpense: () -> Void = {}

    @State private var hasAppeared = false

    var body: some View {
        let insights = viewModel.insights

        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    header

                    if viewModel.transactions.isEmpty {
                        EmptyStateView(
                            symbol: "waveform.path.ecg",
                            title: "Your Pulse is quiet.",
                            message: "Add a few expenses and Money Pulse will start turning them into insights.",
                            buttonTitle: "Add Expense",
                            action: onAddExpense
                        )
                        .transition(.opacity)
                    }

                    ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                        InsightCard(insight: insight, isFeatured: index == 0)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            // Staggered fade-in the first time the screen appears.
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 24)
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.85).delay(Double(index) * 0.06),
                                value: hasAppeared
                            )
                    }

                    if !insights.isEmpty {
                        footnote
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: insights)
            }
            .background(AppBackground())
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { hasAppeared = true }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(Color.pulseGreen)
                    .symbolEffect(.pulse, options: .repeating)
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline.weight(.medium))

            Text("Money Pulse")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("Here’s what your money is doing.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var footnote: some View {
        Label(
            "Insights use only what you've entered in Money Pulse. Estimates are simple arithmetic, not financial advice.",
            systemImage: "info.circle"
        )
        .font(.caption)
        .foregroundStyle(.tertiary)
        .padding(.top, 8)
    }
}

#Preview {
    let viewModel = FinanceViewModel(storage: StorageService(defaults: UserDefaults(suiteName: "preview")!))
    viewModel.loadDemoData()
    return PulseView()
        .environmentObject(viewModel)
        .preferredColorScheme(.dark)
}
