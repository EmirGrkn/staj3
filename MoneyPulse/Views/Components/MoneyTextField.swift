import SwiftUI

/// A decimal-pad text field with the currency symbol in front.
/// It filters input so only digits and a single decimal separator (max 2 decimals) are kept.
///
/// The parent's `@FocusState` is passed in and applied directly to the inner `TextField`.
/// (Applying `.focused` to this whole view from outside would not reach the text field,
/// so the parent could never dismiss the keyboard.)
struct MoneyTextField<Field: Hashable>: View {
    enum Style {
        case standard
        /// Big rounded digits, used for the main amount on the Add screen.
        case large
        /// Right-aligned, used inside `LabeledContent` rows.
        case trailing
    }

    let placeholder: String
    @Binding var text: String
    let currencySymbol: String
    let focus: FocusState<Field?>.Binding
    let field: Field
    var style: Style = .standard

    init(
        _ placeholder: String = "0",
        text: Binding<String>,
        currencySymbol: String,
        focus: FocusState<Field?>.Binding,
        field: Field,
        style: Style = .standard
    ) {
        self.placeholder = placeholder
        self._text = text
        self.currencySymbol = currencySymbol
        self.focus = focus
        self.field = field
        self.style = style
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if style == .trailing {
                Spacer(minLength: 0)
            }
            Text(currencySymbol)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .focused(focus, equals: field)
                .multilineTextAlignment(style == .trailing ? .trailing : .leading)
                .frame(maxWidth: style == .trailing ? 120 : .infinity)
        }
        .font(style == .large ? .system(size: 44, weight: .bold, design: .rounded) : .body)
        .onChange(of: text) { _, newValue in
            let sanitized = Self.sanitize(newValue)
            if sanitized != newValue {
                text = sanitized
            }
        }
    }

    /// Keeps digits and the first "." or ",", limited to two decimal places.
    private static func sanitize(_ input: String) -> String {
        var result = ""
        var hasSeparator = false
        var decimals = 0
        for character in input {
            if character.isNumber {
                if hasSeparator {
                    guard decimals < 2 else { continue }
                    decimals += 1
                }
                result.append(character)
            } else if (character == "." || character == ","), !hasSeparator {
                hasSeparator = true
                result.append(character)
            }
        }
        return result
    }
}
