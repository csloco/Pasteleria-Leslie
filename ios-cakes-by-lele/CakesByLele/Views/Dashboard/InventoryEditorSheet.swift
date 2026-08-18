import SwiftUI

/// Create or edit a pantry item: stock, alert level, package and price.
struct InventoryEditorSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: InventoryItem
    private let isNew: Bool

    init(item: InventoryItem, isNew: Bool = false) {
        _draft = State(initialValue: item)
        self.isNew = isNew
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Artículo") {
                    TextField("Nombre", text: $draft.name)
                    Picker("Categoría", selection: $draft.category) {
                        ForEach(InventoryCategory.allCases) { category in
                            Text(category.label).tag(category)
                        }
                    }
                    Picker("Unidad", selection: $draft.unit) {
                        ForEach(MeasureUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                }

                Section("Existencias") {
                    LabeledContent("Cantidad actual") {
                        TextField("0", value: $draft.stock, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Alerta cuando quede") {
                        TextField("0", value: $draft.minimumStock, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if draft.isLow {
                        Label("Este artículo está por agotarse", systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(Theme.gold)
                    }
                }

                Section("Compra y costo") {
                    TextField("Presentación (ej. bolsa de 2,000 g)", text: $draft.packageLabel)
                    LabeledContent("Cantidad por paquete") {
                        TextField("0", value: $draft.packageQuantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Precio del paquete") {
                        TextField("0", value: $draft.packagePrice, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Costo por \(draft.unit.shortLabel)", value: Fmt.money(draft.pricePerUnit, decimals: 4))
                        .foregroundStyle(Theme.secondaryInk)
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            store.deleteInventory(id: draft.id)
                            dismiss()
                        } label: {
                            Label("Eliminar artículo", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .navigationTitle(isNew ? "Nuevo artículo" : draft.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        store.upsert(item: draft)
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
