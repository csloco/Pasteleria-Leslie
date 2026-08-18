import SwiftUI

/// Editable list of every material needed for one order.
struct MaterialsCard: View {
    @Environment(AppStore.self) private var store
    let order: Order
    var onEdit: (ProductionMaterial) -> Void
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            SectionTitle(text: "Materiales del pedido",
                         accessory: "\(order.readyMaterials)/\(order.materials.count) listos")

            if order.materials.isEmpty {
                Text("Aún no hay materiales. Recalcula la ficha o añade uno manualmente.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(order.materials) { material in
                Button {
                    onEdit(material)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: material.symbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(material.isAutomatic ? Theme.accentDeep : Theme.gold)
                            .frame(width: 32, height: 32)
                            .background((material.isAutomatic ? Theme.accentDeep : Theme.gold).opacity(0.13),
                                        in: .rect(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(material.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                Text(material.quantityLabel)
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.secondaryInk)
                                if !material.isAutomatic {
                                    Text("· añadido")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.gold)
                                }
                                if !material.notes.isEmpty {
                                    Text("· \(material.notes)")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.secondaryInk)
                                        .lineLimit(1)
                                }
                            }
                        }
                        Spacer(minLength: 6)
                        StatusPill(text: material.isReady ? "Listo" : "Pendiente",
                                   color: material.isReady ? Theme.sage : Theme.gold)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.hairline)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        remove(material)
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button {
                        toggleReady(material)
                    } label: {
                        Label(material.isReady ? "Marcar pendiente" : "Marcar listo",
                              systemImage: material.isReady ? "circle" : "checkmark.circle")
                    }
                    Button(role: .destructive) {
                        remove(material)
                    } label: {
                        Label("Eliminar material", systemImage: "trash")
                    }
                }

                if material.id != order.materials.last?.id {
                    Divider().overlay(Theme.hairline)
                }
            }

            HStack(spacing: 10) {
                Button(action: onAdd) {
                    Label("Añadir material", systemImage: "plus.circle")
                }
                .buttonStyle(SoftButtonStyle())

                Button {
                    if let first = order.materials.first { onEdit(first) }
                } label: {
                    Label("Editar cantidad", systemImage: "pencil")
                }
                .buttonStyle(SoftButtonStyle(tint: Theme.secondaryInk))
                .disabled(order.materials.isEmpty)
            }
            .padding(.top, 2)
        }
        .cardSurface()
    }

    private func toggleReady(_ material: ProductionMaterial) {
        guard let orderIndex = store.data.orders.firstIndex(where: { $0.id == order.id }),
              let index = store.data.orders[orderIndex].materials.firstIndex(where: { $0.id == material.id }) else { return }
        store.data.orders[orderIndex].materials[index].isReady.toggle()
    }

    private func remove(_ material: ProductionMaterial) {
        guard let orderIndex = store.data.orders.firstIndex(where: { $0.id == order.id }) else { return }
        store.data.orders[orderIndex].materials.removeAll { $0.id == material.id }
    }
}

/// Sheet to create or edit one production material.
struct MaterialEditorSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let orderID: UUID
    @State private var draft: ProductionMaterial
    private let isNew: Bool

    init(orderID: UUID, material: ProductionMaterial, isNew: Bool) {
        self.orderID = orderID
        _draft = State(initialValue: material)
        self.isNew = isNew
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Material") {
                    TextField("Nombre del material", text: $draft.name)
                    LabeledContent("Cantidad") {
                        TextField("0", value: $draft.quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Unidad", selection: $draft.unit) {
                        ForEach(MeasureUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    Toggle("Listo", isOn: $draft.isReady)
                        .tint(Theme.accentDeep)
                }

                Section("Inventario") {
                    Picker("Artículo relacionado", selection: $draft.inventoryItemID) {
                        Text("Sin relación").tag(Optional<UUID>.none)
                        ForEach(store.data.inventory) { item in
                            Text(item.name).tag(Optional(item.id))
                        }
                    }
                    if let id = draft.inventoryItemID,
                       let item = store.data.inventory.first(where: { $0.id == id }) {
                        LabeledContent("Existencias", value: item.stockLabel)
                        LabeledContent("Costo estimado", value: Fmt.money(draft.quantity * item.pricePerUnit))
                    }
                }

                Section("Notas") {
                    TextField("Notas (opcional)", text: $draft.notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            remove()
                        } label: {
                            Label("Eliminar material", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .navigationTitle(isNew ? "Nuevo material" : "Editar material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let orderIndex = store.data.orders.firstIndex(where: { $0.id == orderID }) else { return }
        if let index = store.data.orders[orderIndex].materials.firstIndex(where: { $0.id == draft.id }) {
            store.data.orders[orderIndex].materials[index] = draft
        } else {
            var material = draft
            material.isAutomatic = false
            if material.symbol == "circle" { material.symbol = "sparkles" }
            store.data.orders[orderIndex].materials.append(material)
        }
        dismiss()
    }

    private func remove() {
        guard let orderIndex = store.data.orders.firstIndex(where: { $0.id == orderID }) else { return }
        store.data.orders[orderIndex].materials.removeAll { $0.id == draft.id }
        dismiss()
    }
}
