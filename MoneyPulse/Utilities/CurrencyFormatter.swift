import Foundation

/// One place for turning numbers into currency strings (and user input back into numbers).
enum CurrencyFormatter {
    /// Formats an amount using the device's locale for grouping/decimal separators,
    /// but always with the symbol of the user's chosen currency ($, €, ₺).
    ///
    /// We use `NumberFormatter` instead of `FormatStyle.Currency` because it lets us force
    /// the symbol — otherwise some locales would display "TRY 120" instead of "₺120".
    static func string(from amount: Double, currency: AppCurrency, showsCents: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.currencySymbol = currency.symbol
        formatter.minimumFractionDigits = showsCents ? 2 : 0
        formatter.maximumFractionDigits = showsCents ? 2 : 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency.symbol)\(amount)"
    }

    /// Parses text typed into a decimal-pad field. Accepts "12.5" and "12,5".
    /// Returns `nil` for empty, negative or invalid input.
    static func parseAmount(_ text: String) -> Double? {
        let cleaned = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value.isFinite, value >= 0 else { return nil }
        return (value * 100).rounded() / 100
    }

    /// Turns a stored amount back into editable text ("1250" or "15.49").
    static func editingString(from amount: Double) -> String {
        guard amount > 0 else { return "" }
        return amount == amount.rounded() ? String(Int(amount)) : String(format: "%.2f", amount)
    }
}
