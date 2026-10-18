import SwiftUI

/// A single insight: icon + label, big number, headline and a short explanation.
struct InsightCard: View {
    let insight: Insight
    /// The first card is shown slightly larger.
    var isFeatured = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: insight.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(insight.type.color)
                    .frame(width: 34, height: 34)
                    .background(insight.type.color.opacity(0.15), in: Circle())

                Text(insight.label.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Spacer()

                if insight.type == .warning {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(insight.type.color.opacity(0.8))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.value)
                    .font(.system(size: isFeatured ? 52 : 40, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())

                Text(insight.title)
                    .font(.headline)
            }

            Text(insight.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle(tint: insight.type.color)
        .accessibilityElement(children: .combine)
    }
}

extension InsightType {
    var color: Color {
        switch self {
        case .positive: .pulseGreen
        case .warning: .orange
        case .neutral: .cyan
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        InsightCard(
            insight: Insight(
                id: "1", type: .warning, label: "Small purchases", value: "$84",
                title: "Small purchases this week",
                description: "9 purchases under $15 added up to $84.",
                symbol: "cup.and.saucer.fill", priority: 1
            ),
            isFeatured: true
        )
        InsightCard(
            insight: Insight(
                id: "2", type: .positive, label: "Savings goal", value: "38%",
                title: "Emergency Fund",
                description: "You've saved $1,900 of your $5,000 goal.",
                symbol: "target", priority: 2
            )
        )
    }
    .padding()
    .background(AppBackground())
    .preferredColorScheme(.dark)
}
