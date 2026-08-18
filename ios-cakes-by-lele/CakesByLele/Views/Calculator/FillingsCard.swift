import SwiftUI

/// One editable filling per separation between sponge layers: type and thickness.
struct FillingsCard: View {
    @Binding var spec: CakeSpec
    let tierIndex: Int

    @State private var customEditing: UUID?

    private var tier: CakeTier? {
        spec.tiers.indices.contains(tierIndex) ? spec.tiers[tierIndex] : nil
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("RELLENOS · \(tier?.fillings.count ?? 0)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.accentDeep)
                Spacer(minLength: 0)
                Text("Entre capas")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }

            if let tier, tier.fillings.isEmpty {
                Text("Añade una segunda capa de bizcocho para tener rellenos.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let tier {
                ForEach(Array(tier.fillings.enumerated()), id: \.element.id) { index, filling in
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "line.3.horizontal")
                                .font(.caption)
                                .foregroundStyle(Theme.hairline)
                            Text("Relleno \(index + 1)")
                                .font(.subheadline)
                                .foregroundStyle(Theme.ink)
                            Spacer(minLength: 6)
                            Picker("", selection: Binding(
                                get: { filling.kind },
                                set: { newValue in updateFilling(id: filling.id) { $0.kind = newValue } }
                            )) {
                                ForEach(FillingKind.allCases) { kind in
                                    Text(kind.label).tag(kind)
                                }
                            }
                            .labelsHidden()
                            .tint(Theme.accentDeep)
                            NumberField(title: "Grosor",
                                        value: Binding(
                                            get: { spec.unit.fromInches(filling.thickness) },
                                            set: { newValue in updateFilling(id: filling.id) { $0.thickness = max(spec.unit.toInches(newValue), 0.05) } }
                                        ),
                                        suffix: spec.unit == .inches ? "\"" : "cm",
                                        width: 70)
                        }
                        if filling.kind == .personalizado {
                            TextField("Nombre del relleno",
                                      text: Binding(
                                        get: { filling.customName },
                                        set: { newValue in updateFilling(id: filling.id) { $0.customName = newValue } }
                                      ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                    if filling.id != tier.fillings.last?.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    applyToAll()
                } label: {
                    Label("Igualar grosores", systemImage: "equal")
                }
                .buttonStyle(SoftButtonStyle(tint: Theme.secondaryInk))
                .disabled((tier?.fillings.count ?? 0) < 2)

                Button {
                    addCustomFilling()
                } label: {
                    Label("Relleno personalizado", systemImage: "plus.circle")
                }
                .buttonStyle(SoftButtonStyle())
                .disabled((tier?.layers.count ?? 6) >= 6)
            }
            .padding(.top, 2)
        }
        .cardSurface()
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: tier?.fillings.count ?? 0)
    }

    private func updateFilling(id: UUID, transform: (inout FillingLayer) -> Void) {
        guard spec.tiers.indices.contains(tierIndex),
              let index = spec.tiers[tierIndex].fillings.firstIndex(where: { $0.id == id }) else { return }
        transform(&spec.tiers[tierIndex].fillings[index])
    }

    private func applyToAll() {
        guard spec.tiers.indices.contains(tierIndex),
              let first = spec.tiers[tierIndex].fillings.first else { return }
        for index in spec.tiers[tierIndex].fillings.indices {
            spec.tiers[tierIndex].fillings[index].thickness = first.thickness
        }
    }

    /// A new filling needs a new sponge layer above it, keeping the structure coherent.
    private func addCustomFilling() {
        guard spec.tiers.indices.contains(tierIndex) else { return }
        var tier = spec.tiers[tierIndex]
        guard tier.layers.count < 6 else { return }
        tier.layers.append(SpongeLayer(height: tier.layers.last?.height ?? 2))
        tier.normalizeFillings()
        if var last = tier.fillings.last {
            last.kind = .personalizado
            last.customName = ""
            tier.fillings[tier.fillings.count - 1] = last
        }
        spec.tiers[tierIndex] = tier
    }
}
