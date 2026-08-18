import SwiftUI

struct StatsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                monthlyChart
                flavorsCard
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .canvasBackground()
        .navigationTitle("Estadísticas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var summaryCard: some View {
        VStack(spacing: 2) {
            SectionTitle(text: "Resumen del mes")
                .padding(.bottom, 6)
            ResultRow(title: "Ventas", value: Fmt.money(store.monthSales, decimals: 0), symbol: "chart.line.uptrend.xyaxis", tint: Theme.sage)
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Gastos", value: Fmt.money(store.monthExpenses, decimals: 0), symbol: "arrow.down", tint: Theme.accentDeep)
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Ganancia", value: Fmt.money(store.monthProfit, decimals: 0), symbol: "chart.bar.fill", tint: Theme.gold, emphasized: true)
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Pedidos entregados",
                      value: "\(store.data.orders.filter { $0.status == .entregado }.count)",
                      symbol: "checkmark.seal",
                      tint: Theme.sage)
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Ticket promedio",
                      value: Fmt.money(averageTicket, decimals: 0),
                      symbol: "tag",
                      tint: Theme.accent)
        }
        .cardSurface()
    }

    private var averageTicket: Double {
        let paid = store.data.orders.filter { $0.status != .cancelado && $0.price > 0 }
        guard !paid.isEmpty else { return 0 }
        return paid.reduce(0) { $0 + $1.price } / Double(paid.count)
    }

    private var monthlyChart: some View {
        let values = lastMonths
        let maximum = max(values.map(\.total).max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Ventas por mes")
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(values, id: \.label) { entry in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.accent.opacity(entry.total > 0 ? 0.9 : 0.25))
                            .frame(height: max(CGFloat(entry.total / maximum) * 110, 6))
                        Text(entry.label)
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140, alignment: .bottom)
        }
        .cardSurface()
    }

    private struct MonthEntry {
        let label: String
        let total: Double
    }

    private var lastMonths: [MonthEntry] {
        let calendar = Calendar.app
        return (0..<6).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let total = store.data.orders
                .filter { calendar.isDate($0.deliveryDate, equalTo: date, toGranularity: .month) && $0.status != .cancelado }
                .reduce(0) { $0 + $1.price }
            let formatter = DateFormatter()
            formatter.locale = Fmt.locale
            formatter.dateFormat = "MMM"
            return MonthEntry(label: formatter.string(from: date).capitalizedFirst, total: total)
        }
    }

    private var flavorsCard: some View {
        let counts = Dictionary(grouping: store.data.orders.filter { !$0.flavor.isEmpty }, by: \.flavor)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        return VStack(spacing: 8) {
            SectionTitle(text: "Sabores más pedidos")
            if counts.isEmpty {
                Text("Aún no hay suficientes pedidos.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(counts.prefix(6), id: \.key) { flavor, count in
                HStack {
                    Text(flavor)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 8)
                    Text("\(count) pedidos")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accentDeep)
                }
                .padding(.vertical, 3)
            }
        }
        .cardSurface()
    }
}
