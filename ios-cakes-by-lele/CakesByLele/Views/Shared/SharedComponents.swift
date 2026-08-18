import SwiftUI

/// Compact metric tile used on the dashboard grid.
struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.14), in: .rect(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryInk)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.accentDeep)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 14)
    }
}

/// Label + value row used inside result cards.
struct ResultRow: View {
    let title: String
    let value: String
    var symbol: String?
    var tint: Color = Theme.accentDeep
    var emphasized: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.13), in: .rect(cornerRadius: 9))
            }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 8)
            Text(value)
                .font(emphasized ? .headline : .subheadline.weight(.semibold))
                .foregroundStyle(emphasized ? Theme.accentDeep : Theme.ink)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
    }
}

/// Rounded field wrapper for numeric text entry.
struct NumberField: View {
    let title: String
    @Binding var value: Double
    var suffix: String = ""
    var width: CGFloat = 78

    var body: some View {
        TextField(title, value: $value, format: .number.precision(.fractionLength(0...2)))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.ink)
            .frame(width: width, height: 36)
            .background(Theme.canvas, in: .rect(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            }
            .overlay(alignment: .trailing) {
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryInk)
                        .padding(.trailing, 6)
                        .allowsHitTesting(false)
                }
            }
    }
}

/// Horizontal chip used for filters and quick selections.
struct ChoiceChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Theme.secondaryInk)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(isSelected ? Theme.accentDeep : Theme.surface, in: .capsule)
                .overlay {
                    Capsule().strokeBorder(isSelected ? Color.clear : Theme.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

/// Empty state shown when a list has no content yet.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .cardSurface()
    }
}

/// Row used in list-like cards, with chevron affordance.
struct NavigationRowLabel: View {
    let title: String
    var subtitle: String?
    var symbol: String
    var tint: Color = Theme.accentDeep

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.13), in: .rect(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.ink)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.hairline)
        }
        .contentShape(.rect)
    }
}

/// Screen header with a large title and optional trailing action.
struct ScreenHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Theme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryInk)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}
