import SwiftUI

/// Fully editable sponge layer structure: count from 1 to 6 with an individual height per layer.
struct SpongeLayersCard: View {
    @Binding var spec: CakeSpec
    let tierIndex: Int
    let recipe: Recipe?

    private var tier: CakeTier? {
        spec.tiers.indices.contains(tierIndex) ? spec.tiers[tierIndex] : nil
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("CAPAS DE BIZCOCHO · \(tier?.layers.count ?? 0)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.accentDeep)
                Spacer(minLength: 8)
                Stepper(value: Binding(get: { tier?.layers.count ?? 1 }, set: setLayerCount), in: 1...6) {
                    EmptyView()
                }
                .labelsHidden()
                .fixedSize()
            }

            if let tier {
                ForEach(Array(tier.layers.enumerated()), id: \.element.id) { index, layer in
                    HStack(spacing: 10) {
                        Image(systemName: "line.3.horizontal")
                            .font(.caption)
                            .foregroundStyle(Theme.hairline)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Capa \(index + 1)")
                                .font(.subheadline)
                                .foregroundStyle(Theme.ink)
                            Text("\(Fmt.length(layer.height, unit: spec.unit)) de alto")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryInk)
                        }
                        Spacer(minLength: 8)
                        NumberField(title: "Alto",
                                    value: Binding(
                                        get: { spec.unit.fromInches(layer.height) },
                                        set: { newValue in updateLayer(id: layer.id, height: spec.unit.toInches(newValue)) }
                                    ),
                                    suffix: spec.unit == .inches ? "\"" : "cm")
                        Button {
                            removeLayer(id: layer.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.footnote)
                                .foregroundStyle(tier.layers.count > 1 ? Theme.accentDeep : Theme.hairline)
                                .frame(width: 34, height: 34)
                        }
                        .buttonStyle(.plain)
                        .disabled(tier.layers.count <= 1)
                    }
                    if layer.id != tier.layers.last?.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    setLayerCount((tier?.layers.count ?? 1) + 1)
                } label: {
                    Label("Añadir capa", systemImage: "plus.circle")
                }
                .buttonStyle(SoftButtonStyle())
                .disabled((tier?.layers.count ?? 0) >= 6)

                Button {
                    restoreRecipeHeights()
                } label: {
                    Label("Restaurar alturas", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(SoftButtonStyle(tint: Theme.secondaryInk))
                .disabled(recipe == nil)
            }
            .padding(.top, 2)
        }
        .cardSurface()
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: tier?.layers.count ?? 0)
    }

    private func setLayerCount(_ count: Int) {
        guard spec.tiers.indices.contains(tierIndex) else { return }
        let target = max(1, min(count, 6))
        var tier = spec.tiers[tierIndex]
        while tier.layers.count > target { tier.layers.removeLast() }
        while tier.layers.count < target {
            tier.layers.append(SpongeLayer(height: tier.layers.last?.height ?? 2))
        }
        tier.normalizeFillings()
        spec.tiers[tierIndex] = tier
    }

    private func updateLayer(id: UUID, height: Double) {
        guard spec.tiers.indices.contains(tierIndex),
              let index = spec.tiers[tierIndex].layers.firstIndex(where: { $0.id == id }) else { return }
        spec.tiers[tierIndex].layers[index].height = max(height, 0.1)
    }

    private func removeLayer(id: UUID) {
        guard spec.tiers.indices.contains(tierIndex), spec.tiers[tierIndex].layers.count > 1 else { return }
        var tier = spec.tiers[tierIndex]
        tier.layers.removeAll { $0.id == id }
        tier.normalizeFillings()
        spec.tiers[tierIndex] = tier
    }

    /// Distributes the reference sponge height of the recipe across the current layers.
    private func restoreRecipeHeights() {
        guard let recipe, spec.tiers.indices.contains(tierIndex) else { return }
        var tier = spec.tiers[tierIndex]
        let perLayer = recipe.referenceSpongeHeight / Double(max(tier.layers.count, 1))
        for index in tier.layers.indices {
            tier.layers[index].height = (perLayer * 100).rounded() / 100
        }
        spec.tiers[tierIndex] = tier
    }
}
