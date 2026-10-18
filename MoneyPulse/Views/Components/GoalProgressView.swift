import SwiftUI

/// Native progress bar with a springy animation when the value changes.
struct GoalProgressView: View {
    let progress: Double
    var tint: Color = .pulseGreen

    var body: some View {
        ProgressView(value: progress)
            .tint(tint)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            .accessibilityValue(progress.formatted(.percent.precision(.fractionLength(0))))
    }
}
