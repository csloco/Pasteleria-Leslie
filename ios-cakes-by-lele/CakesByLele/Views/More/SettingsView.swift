import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var showResetConfirmation = false

    var body: some View {
        @Bindable var bindableStore = store

        Form {
            Section("Pastelería") {
                TextField("Nombre", text: $bindableStore.data.chefName)
            }

            Section("Preferencias de cálculo") {
                Picker("Unidad preferida", selection: $bindableStore.data.defaultUnit) {
                    ForEach(LengthUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                Picker("Tamaño de porción", selection: $bindableStore.data.defaultServingSize) {
                    ForEach(ServingSize.allCases) { size in
                        Text(size.label).tag(size)
                    }
                }
                Stepper("Desperdicio · \(Fmt.percent(store.data.defaultWastePercent))",
                        value: $bindableStore.data.defaultWastePercent,
                        in: 0...0.5,
                        step: 0.05)
                Toggle("Redondear huevos al entero", isOn: $bindableStore.data.roundEggs)
                    .tint(Theme.accentDeep)
            }

            Section("Precios") {
                Stepper("Multiplicador sugerido · \(Fmt.number(store.data.markupMultiplier, decimals: 1))×",
                        value: $bindableStore.data.markupMultiplier,
                        in: 1.5...6,
                        step: 0.1)
                Text("Se usa para proponer el precio de venta a partir del costo de producción.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }

            Section("Datos") {
                LabeledContent("Recetas", value: "\(store.data.recipes.count)")
                LabeledContent("Pedidos", value: "\(store.data.orders.count)")
                LabeledContent("Artículos de inventario", value: "\(store.data.inventory.count)")
                Text("Toda la información se guarda automáticamente en este dispositivo.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Restaurar datos de ejemplo", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.canvas)
        .navigationTitle("Configuración")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialog("¿Restaurar los datos de ejemplo?",
                            isPresented: $showResetConfirmation,
                            titleVisibility: .visible) {
            Button("Restaurar", role: .destructive) { store.resetToSeed() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se reemplazarán tus recetas, pedidos e inventario actuales.")
        }
    }
}
