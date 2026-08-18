import SwiftUI

struct ProductionView: View {
    @Environment(AppStore.self) private var store

    @State private var selectedOrderID: UUID?
    @State private var editingMaterial: ProductionMaterial?
    @State private var isAddingMaterial = false
    @State private var showDeductConfirmation = false

    private var orders: [Order] { store.todayProductionOrders }

    private var activeOrder: Order? {
        if let selectedOrderID, let order = orders.first(where: { $0.id == selectedOrderID }) {
            return order
        }
        return orders.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    if orders.isEmpty {
                        EmptyStateView(symbol: "frying.pan",
                                       title: "Sin producción activa",
                                       message: "Confirma un pedido para verlo en el tablero de producción.")
                    } else {
                        progressCard
                        orderSelector
                        if let order = activeOrder {
                            summaryCard(order)
                            MaterialsCard(order: order,
                                          onEdit: { editingMaterial = $0 },
                                          onAdd: { isAddingMaterial = true })
                            checklistCard(order)
                            if !order.dedication.isEmpty || !order.design.isEmpty || !order.address.isEmpty {
                                deliveryCard(order)
                            }
                            actions(order)
                        }
                    }
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .canvasBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $editingMaterial) { material in
            if let order = activeOrder {
                MaterialEditorSheet(orderID: order.id, material: material, isNew: false)
            }
        }
        .sheet(isPresented: $isAddingMaterial) {
            if let order = activeOrder {
                MaterialEditorSheet(orderID: order.id,
                                    material: ProductionMaterial(name: "", isAutomatic: false),
                                    isNew: true)
            }
        }
        .confirmationDialog("¿Descontar los materiales del inventario?",
                            isPresented: $showDeductConfirmation,
                            titleVisibility: .visible) {
            Button("Descontar del inventario") {
                if let order = activeOrder { store.deductInventory(orderID: order.id) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se restarán las cantidades registradas en la ficha del inventario actual.")
        }
    }

    private var header: some View {
        ScreenHeader(title: "Producción", subtitle: Fmt.dayTitle(Date()))
            .padding(.top, 8)
    }

    private var progressCard: some View {
        let ready = orders.filter { $0.status == .terminado }.count
        let progress = orders.isEmpty ? 0 : Double(ready) / Double(orders.count)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(ready) de \(orders.count) pedidos listos")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(Fmt.percent(progress))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.accentDeep)
                        .monospacedDigit()
                    Text("completado")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryInk)
                }
            }
            ProgressView(value: progress)
                .tint(Theme.accentDeep)
        }
        .cardSurface()
    }

    private var orderSelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(orders) { order in
                    ChoiceChip(title: "\(order.clientName) · \(order.displayTitle)",
                               isSelected: order.id == activeOrder?.id) {
                        selectedOrderID = order.id
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func summaryCard(_ order: Order) -> some View {
        let result = store.calculate(spec: order.spec, recipeID: order.recipeID)
        return VStack(spacing: 2) {
            HStack(spacing: 12) {
                Image(systemName: "birthday.cake.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accentDeep)
                    .frame(width: 38, height: 38)
                    .background(Theme.blush, in: .rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(order.clientName) · \(order.displayTitle)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Entrega · \(Fmt.time(order.deliveryDate))")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                }
                Spacer(minLength: 0)
                StatusPill(text: order.status.label, color: order.status.tint)
            }
            .padding(.bottom, 8)

            Divider().overlay(Theme.hairline)
            ResultRow(title: "Tamaño", value: order.spec.summaryLabel, symbol: "ruler")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Capas · Rellenos",
                      value: "\(order.spec.tiers.first?.layers.count ?? 0) · \(order.spec.tiers.first?.fillings.count ?? 0)",
                      symbol: "square.stack.3d.up")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Altura",
                      value: "\(Fmt.number(order.spec.totalHeight * 2.54, decimals: 1)) cm",
                      symbol: "arrow.up.and.down")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Masa por molde",
                      value: result.tiers.first.map { "\(Fmt.number($0.batterPerMold.rounded())) g × \($0.moldCount)" } ?? "—",
                      symbol: "circle.grid.2x2")
            if !order.dedication.isEmpty {
                Divider().overlay(Theme.hairline)
                ResultRow(title: "Dedicatoria", value: order.dedication, symbol: "heart")
            }
        }
        .cardSurface()
    }

    private func checklistCard(_ order: Order) -> some View {
        VStack(spacing: 8) {
            SectionTitle(text: "Checklist de producción",
                         accessory: "\(order.checklist.filter(\.isDone).count)/\(order.checklist.count)")
            if order.checklist.isEmpty {
                Text("Genera la ficha desde el pedido para crear los pasos.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(order.checklist) { step in
                HStack(spacing: 12) {
                    Image(systemName: step.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(step.isDone ? Theme.accentDeep : Theme.hairline)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(step.title)
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink)
                        if !step.detail.isEmpty {
                            Text(step.detail)
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryInk)
                        }
                    }
                    Spacer(minLength: 8)
                    Toggle("", isOn: Binding(
                        get: { step.isDone },
                        set: { newValue in toggleStep(orderID: order.id, stepID: step.id, value: newValue) }
                    ))
                    .labelsHidden()
                    .tint(Theme.accentDeep)
                }
                .padding(.vertical, 2)
                if step.id != order.checklist.last?.id {
                    Divider().overlay(Theme.hairline)
                }
            }
        }
        .cardSurface()
    }

    private func deliveryCard(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Entrega y decoración")
            if !order.design.isEmpty {
                LabeledContent("Decoración", value: order.design)
            }
            if !order.dedication.isEmpty {
                LabeledContent("Dedicatoria", value: order.dedication)
            }
            LabeledContent("Entrega", value: "\(Fmt.time(order.deliveryDate))\(order.address.isEmpty ? "" : " · \(order.address)")")
        }
        .font(.subheadline)
        .foregroundStyle(Theme.ink)
        .cardSurface()
    }

    private func actions(_ order: Order) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    completeProduction(order)
                } label: {
                    Label("Completar producción", systemImage: "checkmark.seal")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            HStack(spacing: 10) {
                Button {
                    store.refreshProductionTicket(orderID: order.id)
                } label: {
                    Label("Recalcular ficha", systemImage: "arrow.clockwise")
                }
                .buttonStyle(SoftButtonStyle())

                Button {
                    showDeductConfirmation = true
                } label: {
                    Label(order.inventoryDeducted ? "Ya descontado" : "Descontar inventario",
                          systemImage: "shippingbox")
                }
                .buttonStyle(SoftButtonStyle(tint: Theme.sage))
                .disabled(order.inventoryDeducted)
            }
        }
    }

    private func toggleStep(orderID: UUID, stepID: UUID, value: Bool) {
        guard let orderIndex = store.data.orders.firstIndex(where: { $0.id == orderID }),
              let stepIndex = store.data.orders[orderIndex].checklist.firstIndex(where: { $0.id == stepID }) else { return }
        store.data.orders[orderIndex].checklist[stepIndex].isDone = value
    }

    private func completeProduction(_ order: Order) {
        guard let index = store.data.orders.firstIndex(where: { $0.id == order.id }) else { return }
        store.data.orders[index].status = .terminado
        for stepIndex in store.data.orders[index].checklist.indices {
            store.data.orders[index].checklist[stepIndex].isDone = true
        }
        for materialIndex in store.data.orders[index].materials.indices {
            store.data.orders[index].materials[materialIndex].isReady = true
        }
    }
}

#Preview {
    ProductionView()
        .environment(AppStore())
}
