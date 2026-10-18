import Foundation

enum InsightType {
    case positive
    case warning
    case neutral
}

/// One card on the Pulse screen. Built by `InsightBuilder` from the user's data.
struct Insight: Identifiable, Equatable {
    /// A stable id (e.g. "weekly-spending") so SwiftUI can animate a card's
    /// value changing instead of replacing the whole card.
    let id: String
    let type: InsightType
    /// Small uppercase label shown above the number, e.g. "LAST 7 DAYS".
    let label: String
    /// The large number, e.g. "$126".
    let value: String
    let title: String
    let description: String
    let symbol: String
    /// Lower numbers are shown first.
    let priority: Int
}
