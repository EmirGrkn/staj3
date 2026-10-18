import Foundation

/// Currencies the app supports. Stored by ISO code so it survives app updates.
enum AppCurrency: String, Codable, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case tryLira = "TRY"

    var id: String { rawValue }
    var code: String { rawValue }

    var symbol: String {
        switch self {
        case .usd: "$"
        case .eur: "€"
        case .tryLira: "₺"
        }
    }

    /// e.g. "USD $"
    var label: String { "\(code) \(symbol)" }
}

struct UserSettings: Codable, Equatable {
    var monthlyIncome: Double
    var monthlySavingsTarget: Double
    var currency: AppCurrency

    var currencySymbol: String { currency.symbol }

    static let `default` = UserSettings(monthlyIncome: 0, monthlySavingsTarget: 0, currency: .usd)
}
