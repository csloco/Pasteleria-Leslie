import SwiftUI

struct DashboardView: View {
    @Environment(AppStore.self) private var store
    @Binding var selection: Int

    @State private var selectedDate: Date = Date()
    @State private var monthAnchor: Date = Date()
    @State private var editingItem: InventoryItem?
    @State private var isCreatingItem = false
    @State private var isCreatingOrder = false
    @State private var dayDetail: Date?

    private var today: Date { Date() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    metricsGrid
                    financeCard
                    CalendarCard(anchor: $monthAnchor,
                                 selectedDate: $selectedDate,
                                 store: store) { date in
                        dayDetail = date
                    }
                    inventoryCard
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .canvasBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $editingItem) { item in
            InventoryEditorSheet(item: item)
        }
        .sheet(isPresented: $isCreatingItem) {
            InventoryEditorSheet(item: InventoryItem(name: "", category: .otros), isNew: true)
        }
        .sheet(isPresented: $isCreatingOrder) {
            OrderEditorView(order: Order(), isNew: true)
        }
        .sheet(item: $dayDetail) { date in
            DayAgendaSheet(date: date)
        }
    }

    // MARK: - Header

    private var header: some View {
        ScreenHeader(title: "\(Fmt.greeting(for: today)), \(store.data.chefName)",
                     subtitle: Fmt.dayTitle(today)) {
            Button {
                isCreatingOrder = true
            } label: {
                Label("Nuevo pedido", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accentDeep)
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .background(Theme.blush, in: .capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    // MARK: - Metrics

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            Button { selection = 1 } label: {
                MetricCard(title: "Pedidos para hoy",
                           value: "\(store.todayOrders.count)",
                           symbol: "bag.fill",
                           tint: Theme.accentDeep)
            }
            .buttonStyle(.plain)

            Button { selection = 1 } label: {
                MetricCard(title: "Por confirmar",
                           value: "\(store.pendingConfirmation.count)",
                           symbol: "clock.fill",
                           tint: Theme.gold)
            }
            .buttonStyle(.plain)

            Button { selection = 1 } label: {
                MetricCard(title: "Pendientes de pago",
                           value: Fmt.money(store.pendingPayment.reduce(0) { $0 + $1.balance }, decimals: 0),
                           symbol: "wallet.bifold.fill",
                           tint: Theme.accent)
            }
            .buttonStyle(.plain)

            Button { selection = 3 } label: {
                MetricCard(title: "Entregas próximas",
                           value: "\(store.upcomingOrders.count)",
                           symbol: "shippingbox.fill",
                           tint: Theme.sage)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Finance

    private var financeCard: some View {
        VStack(spacing: 4) {
            SectionTitle(text: "Resumen financiero del mes")
                .padding(.bottom, 6)
            NavigationLink {
                StatsView()
            } label: {
                ResultRow(title: "Ventas del mes",
                          value: Fmt.money(store.monthSales, decimals: 0),
                          symbol: "chart.line.uptrend.xyaxis",
                          tint: Theme.sage)
            }
            .buttonStyle(.plain)
            Divider().overlay(Theme.hairline)
            NavigationLink {
                CostsView()
            } label: {
                ResultRow(title: "Gastos del mes",
                          value: Fmt.money(store.monthExpenses, decimals: 0),
                          symbol: "arrow.down",
                          tint: Theme.accentDeep)
            }
            .buttonStyle(.plain)
            Divider().overlay(Theme.hairline)
            NavigationLink {
                StatsView()
            } label: {
                ResultRow(title: "Ganancia aproximada",
                          value: Fmt.money(store.monthProfit, decimals: 0),
                          symbol: "chart.bar.fill",
                          tint: Theme.gold)
            }
            .buttonStyle(.plain)
        }
        .cardSurface()
    }

    // MARK: - Inventory

    private var inventoryCard: some View {
        VStack(spacing: 10) {
            SectionTitle(text: "Inventario", accessory: "\(store.lowStockItems.count) por reponer")

            ForEach(inventoryHighlights) { item in
                Button {
                    editingItem = item
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.category.systemImage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(item.isLow ? Theme.gold : Theme.sage)
                            .frame(width: 32, height: 32)
                            .background((item.isLow ? Theme.gold : Theme.sage).opacity(0.14), in: .rect(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.ink)
                            Text("\(item.stockLabel) · \(item.minimumLabel)")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryInk)
                        }
                        Spacer(minLength: 6)
                        StatusPill(text: item.isLow ? "Bajo" : "Suficiente",
                                   color: item.isLow ? Theme.gold : Theme.sage)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.hairline)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                if item.id != inventoryHighlights.last?.id {
                    Divider().overlay(Theme.hairline)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                inventoryAction(title: "Añadir\nartículo", symbol: "plus") {
                    isCreatingItem = true
                }
                inventoryAction(title: "Editar\nexistencias", symbol: "pencil") {
                    editingItem = inventoryHighlights.first ?? store.data.inventory.first
                }
                inventoryAction(title: "Ajustar\nalerta", symbol: "bell") {
                    editingItem = store.lowStockItems.first ?? store.data.inventory.first
                }
                NavigationLink {
                    InventoryView()
                } label: {
                    inventoryActionLabel(title: "Ver inventario\ncompleto", symbol: "list.bullet")
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .cardSurface()
    }

    private var inventoryHighlights: [InventoryItem] {
        let low = store.lowStockItems
        if low.count >= 3 { return Array(low.prefix(3)) }
        let others = store.data.inventory.filter { !$0.isLow }.sorted { $0.name < $1.name }
        return Array((low + others).prefix(3))
    }

    private func inventoryAction(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            inventoryActionLabel(title: title, symbol: symbol)
        }
        .buttonStyle(.plain)
    }

    private func inventoryActionLabel(title: String, symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accentDeep)
            Text(title)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .background(Theme.canvas, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }
}

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

#Preview {
    DashboardView(selection: .constant(0))
        .environment(AppStore())
}
