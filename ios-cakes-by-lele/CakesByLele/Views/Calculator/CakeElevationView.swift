import SwiftUI

/// Front elevation schematic of the cake: every tier with its sponge layers and fillings.
struct CakeElevationView: View {
    let spec: CakeSpec
    var highlightedTierID: UUID?

    private var maxWidthInches: Double {
        max(spec.tiers.map(\.primarySize).max() ?? 8, 1)
    }

    private var totalHeightInches: Double {
        max(spec.totalHeight, 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width * 0.72
            let availableHeight = proxy.size.height
            let scale = min(availableWidth / maxWidthInches, availableHeight / totalHeightInches)

            VStack(spacing: 2) {
                ForEach(Array(spec.tiers.enumerated()), id: \.element.id) { index, tier in
                    tierView(tier: tier,
                             index: index,
                             scale: scale)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func tierView(tier: CakeTier, index: Int, scale: Double) -> some View {
        let width = max(tier.primarySize * scale, 40)
        let isHighlighted = highlightedTierID == nil || highlightedTierID == tier.id

        return VStack(spacing: 0) {
            ForEach(Array(interleaved(tier: tier).enumerated()), id: \.offset) { _, slice in
                Rectangle()
                    .fill(slice.color)
                    .frame(width: width, height: max(slice.height * scale, 3))
            }
        }
        .clipShape(.rect(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Theme.hairline, lineWidth: 0.8)
        }
        .opacity(isHighlighted ? 1 : 0.45)
        .overlay(alignment: .trailing) {
            Text(tier.sizeLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.secondaryInk)
                .offset(x: 42)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: width)
    }

    private struct Slice {
        let height: Double
        let color: Color
    }

    /// Sponge / filling / sponge ... from top to bottom.
    private func interleaved(tier: CakeTier) -> [Slice] {
        var slices: [Slice] = []
        for (index, layer) in tier.layers.enumerated() {
            slices.append(Slice(height: layer.height, color: spongeColor))
            if index < tier.fillings.count {
                slices.append(Slice(height: tier.fillings[index].thickness, color: fillingColor(tier.fillings[index].kind)))
            }
        }
        return slices
    }

    private var spongeColor: Color { Color(red: 0.945, green: 0.847, blue: 0.643) }

    private func fillingColor(_ kind: FillingKind) -> Color {
        switch kind {
        case .ganache, .chocolate: return Color(red: 0.408, green: 0.251, blue: 0.192)
        case .dulceDeLeche: return Color(red: 0.749, green: 0.510, blue: 0.271)
        case .buttercream: return Color(red: 0.980, green: 0.929, blue: 0.878)
        case .crema: return Color(red: 0.976, green: 0.965, blue: 0.941)
        case .fresa: return Color(red: 0.906, green: 0.596, blue: 0.639)
        case .personalizado: return Color(red: 0.867, green: 0.804, blue: 0.706)
        }
    }
}
