import SwiftUI

/// Friendly placeholder with a single call-to-action, built on `ContentUnavailableView`.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
                .foregroundStyle(.primary)
        } description: {
            Text(message)
        } actions: {
            Button(action: action) {
                Text(buttonTitle)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(.black)
        }
        .cardStyle(tint: .pulseGreen)
    }
}

#Preview {
    EmptyStateView(
        symbol: "waveform.path.ecg",
        title: "Your Pulse is quiet.",
        message: "Add a few expenses and Money Pulse will start turning them into insights.",
        buttonTitle: "Add Expense",
        action: {}
    )
    .padding()
    .background(AppBackground())
    .preferredColorScheme(.dark)
}
