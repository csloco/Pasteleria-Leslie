import SwiftUI

/// Shared visual system for Cakes by Lele.
enum Theme {
    static let canvas = Color(red: 0.984, green: 0.973, blue: 0.957)
    static let surface = Color.white
    static let ink = Color(red: 0.188, green: 0.149, blue: 0.149)
    static let secondaryInk = Color(red: 0.463, green: 0.416, blue: 0.408)
    static let accent = Color(red: 0.851, green: 0.549, blue: 0.604)
    static let accentDeep = Color(red: 0.788, green: 0.471, blue: 0.525)
    static let sage = Color(red: 0.651, green: 0.722, blue: 0.647)
    static let gold = Color(red: 0.780, green: 0.651, blue: 0.420)
    static let blush = Color(red: 0.976, green: 0.929, blue: 0.933)
    static let hairline = Color(red: 0.902, green: 0.878, blue: 0.863)
}

/// Elevated card surface used across every screen.
struct CardSurface: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface, in: .rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(Theme.hairline.opacity(0.7), lineWidth: 0.7)
            }
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func cardSurface(padding: CGFloat = 16) -> some View {
        modifier(CardSurface(padding: padding))
    }

    /// Standard screen background with the warm ivory canvas.
    func canvasBackground() -> some View {
        background(Theme.canvas.ignoresSafeArea())
    }
}

/// Small section title used inside cards.
struct SectionTitle: View {
    let text: String
    var accessory: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            if let accessory {
                Text(accessory)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
            }
            Spacer(minLength: 0)
        }
    }
}

/// Pill used for order states and stock levels — always color plus text.
struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: .capsule)
    }
}

/// Primary call to action matching the approved direction.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Theme.accentDeep, in: .rect(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    var tint: Color = Theme.accentDeep

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(Theme.surface, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(tint.opacity(0.35), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
