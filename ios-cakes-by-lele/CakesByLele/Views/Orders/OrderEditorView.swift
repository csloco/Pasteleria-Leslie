import SwiftUI

/// Create or edit an Instagram order, including its cake configuration.
struct OrderEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Order
    @State private var isEditingCake = false
    private let isNew: Bool

    init(order: Order, isNew: Bool) {
        _draft = State(initialValue: order)
        self.isNew = isNew
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cliente") {
                    TextField("Nombre del cliente", text: $draft.clientName)
                    TextField("Usuario de Instagram", text: $draft.instagram)
                        .textInputAutocapitalization(.never)
                    TextField("Teléfono", text: $draft.phone)
                        .keyboardType(.phonePad)
                }

                Section("Entrega") {
                    DatePicker("Fecha y hora", selection: $draft.deliveryDate)
                    Picker("Estado", selection: $draft.status) {
                        ForEach(OrderStatus.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }
                    TextField("Dirección de entrega", text: $draft.address)
                }

                Section("Pastel") {
                    TextField("Título del pedido", text: $draft.cakeTitle)
                    Picker("Receta base", selection: $draft.recipeID) {
                        Text("Sin receta").tag(Optional<UUID>.none)
                        ForEach(store.data.recipes) { recipe in
                            Text("\(recipe.emoji) \(recipe.name)").tag(Optional(recipe.id))
                        }
                    }
                    LabeledContent("Configuración", value: draft.spec.summaryLabel)
                    LabeledContent("Altura total", value: "\(Fmt.number(draft.spec.totalHeight * 2.54, decimals: 1)) cm")
                    Button {
                        isEditingCake = true
                    } label: {
                        Label("Editar capas, rellenos y pisos", systemImage: "square.stack.3d.up")
                    }
                }

                Section("Diseño") {
                    TextField("Diseño solicitado", text: $draft.design, axis: .vertical)
                        .lineLimit(1...4)
                    TextField("Dedicatoria", text: $draft.dedication)
                    TextField("Foto de referencia (enlace)", text: $draft.referenceImageURL)
                        .textInputAutocapitalization(.never)
                }

                Section("Pago") {
                    LabeledContent("Precio total") {
                        TextField("0", value: $draft.price, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Anticipo") {
                        TextField("0", value: $draft.deposit, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Costo de envío") {
                        TextField("0", value: $draft.shippingCost, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Forma de pago", selection: $draft.paymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Text(method.label).tag(method)
                        }
                    }
                    LabeledContent("Saldo pendiente", value: Fmt.money(draft.balance, decimals: 0))
                        .foregroundStyle(draft.isPaid ? Theme.sage : Theme.gold)
                }

                Section("Notas") {
                    TextField("Notas internas", text: $draft.notes, axis: .vertical)
                        .lineLimit(1...5)
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            store.deleteOrder(id: draft.id)
                            dismiss()
                        } label: {
                            Label("Eliminar pedido", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .navigationTitle(isNew ? "Nuevo pedido" : "Editar pedido")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(draft.clientName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $isEditingCake) {
                CakeStructureSheet(spec: $draft.spec)
            }
        }
    }

    private func save() {
        if draft.flavor.isEmpty, let recipe = store.recipe(id: draft.recipeID) {
            draft.flavor = recipe.name
        }
        store.upsert(order: draft)
        if draft.status.isProduction {
            store.refreshProductionTicket(orderID: draft.id)
        }
        dismiss()
    }
}

/// Reusable editor for tiers, sponge layers and fillings inside an order.
struct CakeStructureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var spec: CakeSpec
    @State private var tierIndex = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    tierPicker
                    SpongeLayersCard(spec: $spec, tierIndex: clampedIndex, recipe: nil)
                    FillingsCard(spec: $spec, tierIndex: clampedIndex)
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Altura total")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryInk)
                            Text(Fmt.length(spec.totalHeight, unit: spec.unit))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Theme.accentDeep)
                        }
                        Spacer(minLength: 0)
                        CakeElevationView(spec: spec, highlightedTierID: spec.tiers[safe: clampedIndex]?.id)
                            .frame(width: 130, height: 120)
                    }
                    .cardSurface()
                }
                .padding(16)
            }
            .canvasBackground()
            .navigationTitle("Estructura del pastel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }

    private var clampedIndex: Int {
        min(max(tierIndex, 0), max(spec.tiers.count - 1, 0))
    }

    private var tierPicker: some View {
        VStack(spacing: 12) {
            HStack {
                SectionTitle(text: "Pisos")
                Spacer(minLength: 0)
                Stepper(value: Binding(get: { spec.tiers.count }, set: setTierCount), in: 1...4) {
                    Text("\(spec.tiers.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                }
                .labelsHidden()
                .fixedSize()
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(spec.tiers.enumerated()), id: \.element.id) { index, tier in
                        ChoiceChip(title: "\(CakeSpec.tierName(index: index, total: spec.tiers.count)) · \(tier.sizeLabel)",
                                   isSelected: index == clampedIndex) {
                            tierIndex = index
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)

            if let tier = spec.tiers[safe: clampedIndex] {
                HStack(spacing: 10) {
                    Text(tier.shape.primaryLabel)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                    NumberField(title: "Medida",
                                value: Binding(
                                    get: { spec.unit.fromInches(tier.primarySize) },
                                    set: { newValue in spec.tiers[clampedIndex].primarySize = spec.unit.toInches(newValue) }
                                ),
                                suffix: spec.unit == .inches ? "\"" : "cm")
                }
            }
        }
        .cardSurface()
    }

    private func setTierCount(_ count: Int) {
        let target = max(1, min(count, 4))
        while spec.tiers.count > target { spec.tiers.removeLast() }
        while spec.tiers.count < target {
            var tier = spec.tiers.last ?? CakeTier()
            tier.id = UUID()
            tier.primarySize += 2
            tier.layers = tier.layers.map { SpongeLayer(height: $0.height) }
            tier.fillings = tier.fillings.map { FillingLayer(kind: $0.kind, customName: $0.customName, thickness: $0.thickness) }
            spec.tiers.append(tier)
        }
        tierIndex = min(tierIndex, spec.tiers.count - 1)
    }
}

nonisolated extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
