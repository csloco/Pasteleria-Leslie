import SwiftUI

/// Adds up the ingredients of every order on a chosen date and compares with stock.
struct ShoppingListView: View {
    @Environment(AppStore.self) private var store
    @State private var date = Date()
    @State private var selectedOrderIDs: Set<UUID> = []

    private var dayOrders: [Order] {
        store.orders(on: date)
    }

    private var chosenOrders: [Order] {
        selectedOrderIDs.isEmpty ? dayOrders : dayOrders.filter { selectedOrderIDs.contains($0.id) }
    }

    private var lines: [ShoppingLine] {
        store.shoppingList(for: chosenOrders)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    DatePicker("Fecha de los pedidos", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(Theme.accentDeep)
                    if dayOrders.isEmpty {
                        Text("No hay pedidos para esta fecha.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(dayOrders) { order in
                            Button {
                                toggle(order.id)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: isSelected(order.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isSelected(order.id) ? Theme.accentDeep : Theme.hairline)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("\(order.clientName) · \(order.displayTitle)")
                                            .font(.subheadline)
                                            .foregroundStyle(Theme.ink)
                                        Text(order.status.label)
                                            .font(.caption)
                                            .foregroundStyle(Theme.secondaryInk)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .cardSurface()

                if !lines.isEmpty {
                    VStack(spacing: 8) {
                        SectionTitle(text: "Necesitas", accessory: "\(chosenOrders.count) pedidos")
                        ForEach(lines) { line in
                            VStack(spacing: 4) {
                                HStack {
                                    Text(line.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Theme.ink)
                                    Spacer(minLength: 8)
                                    Text("\(Fmt.number(line.needed)) \(line.unit.shortLabel)")
                                        .font(.subheadline.weight(.semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(Theme.ink)
                                }
                                HStack {
                                    Text("Tienes \(Fmt.number(line.available)) \(line.unit.shortLabel)")
                                        .font(.caption)
                                        .foregroundStyle(Theme.secondaryInk)
                                    Spacer(minLength: 8)
                                    if line.isCovered {
                                        StatusPill(text: "Cubierto", color: Theme.sage)
                                    } else {
                                        StatusPill(text: "Comprar \(Fmt.number(line.toBuy)) \(line.unit.shortLabel)",
                                                   color: Theme.gold)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            if line.id != lines.last?.id {
                                Divider().overlay(Theme.hairline)
                            }
                        }
                    }
                    .cardSurface()

                    VStack(spacing: 2) {
                        SectionTitle(text: "Lista de compras")
                            .padding(.bottom, 6)
                        ForEach(lines.filter { !$0.isCovered }) { line in
                            ResultRow(title: line.name,
                                      value: "\(Fmt.number(line.toBuy)) \(line.unit.shortLabel) · \(Fmt.money(line.estimatedCost))",
                                      symbol: "cart")
                            Divider().overlay(Theme.hairline)
                        }
                        ResultRow(title: "Costo estimado",
                                  value: Fmt.money(lines.reduce(0) { $0 + $1.estimatedCost }),
                                  symbol: "banknote",
                                  tint: Theme.gold,
                                  emphasized: true)
                    }
                    .cardSurface()
                }
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .canvasBackground()
        .navigationTitle("Lista de compras")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func isSelected(_ id: UUID) -> Bool {
        selectedOrderIDs.isEmpty || selectedOrderIDs.contains(id)
    }

    private func toggle(_ id: UUID) {
        if selectedOrderIDs.isEmpty {
            selectedOrderIDs = Set(dayOrders.map(\.id))
        }
        if selectedOrderIDs.contains(id) {
            selectedOrderIDs.remove(id)
        } else {
            selectedOrderIDs.insert(id)
        }
    }
}
