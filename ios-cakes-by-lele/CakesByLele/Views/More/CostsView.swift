import SwiftUI

/// Cost per gram of every ingredient plus the profit breakdown of an order.
struct CostsView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedOrderID: UUID?

    private var orders: [Order] {
        store.data.orders.filter { $0.status != .cancelado }.sorted { $0.deliveryDate > $1.deliveryDate }
    }

    private var order: Order? {
        if let selectedOrderID { return orders.first { $0.id == selectedOrderID } }
        return orders.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let order {
                    orderPicker
                    breakdown(order)
                }
                pricePerUnitCard
                expensesCard
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .canvasBackground()
        .navigationTitle("Costos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var orderPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(orders.prefix(12)) { item in
                    ChoiceChip(title: "\(item.clientName) · \(item.displayTitle)",
                               isSelected: item.id == order?.id) {
                        selectedOrderID = item.id
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func breakdown(_ order: Order) -> some View {
        let result = store.calculate(spec: order.spec, recipeID: order.recipeID)
        let boxCost = 9.0
        let baseCost = 6.5
        let production = result.productionCost + boxCost + baseCost + order.extraCosts + order.shippingCost
        let revenue = order.price + order.shippingCost
        let profit = revenue - production
        let margin = revenue > 0 ? profit / revenue : 0

        return VStack(spacing: 2) {
            SectionTitle(text: "Desglose del pedido", accessory: order.displayTitle)
                .padding(.bottom, 6)
            ResultRow(title: "Bizcocho", value: Fmt.money(result.ingredientCost), symbol: "birthday.cake")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Relleno", value: Fmt.money(result.fillingCost), symbol: "drop")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Cobertura", value: Fmt.money(result.coatingCost), symbol: "paintbrush")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Caja y base", value: Fmt.money(boxCost + baseCost), symbol: "shippingbox")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Envío", value: Fmt.money(order.shippingCost), symbol: "car")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Costo total de producción", value: Fmt.money(production), symbol: "sum", emphasized: true)
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Precio de venta", value: Fmt.money(revenue), symbol: "tag", tint: Theme.sage)
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Ganancia",
                      value: Fmt.money(profit),
                      symbol: "arrow.up.right",
                      tint: profit >= 0 ? Theme.sage : Theme.accentDeep,
                      emphasized: true)
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Margen", value: Fmt.percent(margin), symbol: "percent", tint: Theme.gold)
        }
        .cardSurface()
    }

    private var pricePerUnitCard: some View {
        VStack(spacing: 8) {
            SectionTitle(text: "Precio por unidad de compra")
            ForEach(store.data.inventory) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink)
                        Text(item.packageLabel.isEmpty
                             ? "\(Fmt.number(item.packageQuantity)) \(item.unit.shortLabel) · \(Fmt.money(item.packagePrice, decimals: 0))"
                             : "\(item.packageLabel) · \(Fmt.money(item.packagePrice, decimals: 0))")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                    Spacer(minLength: 8)
                    Text("\(Fmt.money(item.pricePerUnit, decimals: 4))/\(item.unit.shortLabel)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.accentDeep)
                }
                .padding(.vertical, 3)
                if item.id != store.data.inventory.last?.id {
                    Divider().overlay(Theme.hairline)
                }
            }
        }
        .cardSurface()
    }

    private var expensesCard: some View {
        @Bindable var bindableStore = store
        return VStack(spacing: 10) {
            SectionTitle(text: "Gastos del mes")
            HStack {
                Text("Total registrado")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                TextField("0", value: $bindableStore.data.expenses, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 110)
            }
        }
        .cardSurface()
    }
}
