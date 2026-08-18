import SwiftUI

/// Monthly calendar with dots per order state, used on the dashboard.
struct CalendarCard: View {
    @Binding var anchor: Date
    @Binding var selectedDate: Date
    let store: AppStore
    var onSelectDay: (Date) -> Void

    private let calendar = Calendar.app
    private let weekdaySymbols = ["L", "M", "M", "J", "V", "S", "D"]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(Fmt.monthTitle(anchor))
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button {
                    shiftMonth(-1)
                } label: {
                    monthChevron("chevron.left")
                }
                .buttonStyle(.plain)
                Button {
                    shiftMonth(1)
                } label: {
                    monthChevron("chevron.right")
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryInk)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    dayCell(day)
                }
            }

            legend
        }
        .cardSurface()
        .animation(.easeInOut(duration: 0.2), value: anchor)
    }

    private func monthChevron(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.accentDeep)
            .frame(width: 34, height: 34)
            .background(Theme.blush, in: .circle)
    }

    private func dayCell(_ day: Date) -> some View {
        let inMonth = calendar.isDate(day, equalTo: anchor, toGranularity: .month)
        let orders = store.orders(on: day)
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)

        return Button {
            selectedDate = day
            if !orders.isEmpty { onSelectDay(day) }
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline.weight(isToday || isSelected ? .bold : .regular))
                    .foregroundStyle(dayColor(inMonth: inMonth, isSelected: isSelected, orders: orders))
                    .frame(width: 30, height: 30)
                    .background {
                        if isSelected {
                            Circle().fill(Theme.accentDeep)
                        } else if isToday {
                            Circle().strokeBorder(Theme.accent, lineWidth: 1.5)
                        }
                    }
                HStack(spacing: 3) {
                    ForEach(Array(dotColors(for: orders).enumerated()), id: \.offset) { _, color in
                        Circle().fill(color).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func dayColor(inMonth: Bool, isSelected: Bool, orders: [Order]) -> Color {
        if isSelected { return .white }
        if !inMonth { return Theme.hairline }
        return Theme.ink
    }

    private func dotColors(for orders: [Order]) -> [Color] {
        var colors: [Color] = []
        if orders.contains(where: { $0.status.isProduction }) { colors.append(Theme.accent) }
        if orders.contains(where: { $0.status == .confirmado || $0.status == .terminado }) { colors.append(Theme.sage) }
        if orders.contains(where: { !$0.status.isProduction && $0.status.isOpen }) { colors.append(Theme.gold) }
        return Array(colors.prefix(3))
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: Theme.accent, text: "En producción")
            legendItem(color: Theme.sage, text: "Confirmados")
            legendItem(color: Theme.gold, text: "Por confirmar")
            Spacer(minLength: 0)
        }
        .font(.caption2)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text).foregroundStyle(Theme.secondaryInk)
        }
    }

    private func shiftMonth(_ value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: anchor) {
            anchor = next
        }
    }

    /// Six weeks of days covering the visible month grid.
    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: anchor),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: firstWeek.start) }
    }
}

/// Sheet listing everything that happens on a chosen day.
struct DayAgendaSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let date: Date

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(groups, id: \.title) { group in
                        if !group.orders.isEmpty {
                            VStack(spacing: 10) {
                                SectionTitle(text: group.title, accessory: "\(group.orders.count)")
                                ForEach(group.orders) { order in
                                    NavigationLink {
                                        OrderDetailView(orderID: order.id)
                                    } label: {
                                        NavigationRowLabel(title: "\(order.clientName) · \(order.displayTitle)",
                                                           subtitle: "\(order.status.label) · \(Fmt.time(order.deliveryDate))",
                                                           symbol: "birthday.cake",
                                                           tint: order.status.tint)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .cardSurface()
                        }
                    }
                    if store.orders(on: date).isEmpty {
                        EmptyStateView(symbol: "calendar",
                                       title: "Sin pedidos",
                                       message: "No hay entregas programadas para este día.")
                    }
                }
                .padding(16)
            }
            .canvasBackground()
            .navigationTitle(Fmt.dayTitle(date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }

    private struct Group {
        let title: String
        let orders: [Order]
    }

    private var groups: [Group] {
        let orders = store.orders(on: date)
        return [
            Group(title: "Hornear", orders: orders.filter { $0.status == .confirmado || $0.status == .porPreparar }),
            Group(title: "Rellenar y cubrir", orders: orders.filter { $0.status == .horneado }),
            Group(title: "Decorar", orders: orders.filter { $0.status == .decorando }),
            Group(title: "Entregar", orders: orders.filter { $0.status == .terminado || $0.status == .entregado }),
            Group(title: "Por confirmar", orders: orders.filter { !$0.status.isProduction && $0.status != .entregado })
        ]
    }
}
