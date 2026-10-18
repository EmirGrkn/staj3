import SwiftUI

// Small shared styling helpers used across the app.

extension Color {
    static let appBackground = Color(red: 0.035, green: 0.043, blue: 0.067)
    static let cardBackground = Color(red: 0.094, green: 0.106, blue: 0.145)
    static let pulseGreen = Color(red: 0.25, green: 0.88, blue: 0.62)
}

/// Dark background with a soft green glow at the top.
struct AppBackground: View {
    var body: some View {
        ZStack {
            Color.appBackground
            RadialGradient(
                colors: [Color.pulseGreen.opacity(0.16), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

/// Rounded card look with an optional tinted gradient in the corner.
struct CardStyle: ViewModifier {
    var tint: Color = .clear

    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
                shape
                    .fill(Color.cardBackground)
                    .overlay {
                        shape.fill(
                            LinearGradient(
                                colors: [tint.opacity(0.22), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    .overlay {
                        shape.strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    }
            }
    }
}

extension View {
    func cardStyle(tint: Color = .clear) -> some View {
        modifier(CardStyle(tint: tint))
    }
}

/// Full-width green button used in onboarding.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(Color.pulseGreen, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}
