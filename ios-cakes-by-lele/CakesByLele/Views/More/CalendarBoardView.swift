import SwiftUI

/// Monthly and weekly production calendar with the tasks of each day.
struct CalendarBoardView: View {
    @Environment(AppStore.self) private var store

    @State private var anchor = Date()
    @State private var selectedDate = Date()
    @State private var mode: Mode = .month
    @State private var dayDetail: Date?

    enum Mode: String, CaseIterable, Identifiable {
        case month = "Mensual"
        case week = "Semanal"
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("", selection: $mode) {
                    ForEach(Mode.allCases) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                .pickerStyle(.segmented)

                if mode == .month {
                    CalendarCard(anchor: $anchor, selectedDate: $selectedDate, store: store) { date in
                        dayDetail = date
                    }
                } else {
                    weekStrip
                }

                dayTasks
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .canvasBackground()
        .navigationTitle("Calendario")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $dayDetail) { date in
            DayAgendaSheet(date: date)
        }
    }

    private var weekStrip: some View {
        VStack(spacing: 12) {
            HStack {
                Text(Fmt.monthTitle(selectedDate))
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
            }
            HStack(spacing: 6) {
                ForEach(weekDays, id: \.self) { day in
                    let orders = store.orders(on: day)
                    Button {
                        selectedDate = day
                    } label: {
                        VStack(spacing: 6) {
                            Text(shortWeekday(day))
                                .font(.caption2)
                                .foregroundStyle(Theme.secondaryInk)
                            Text("\(Calendar.app.component(.day, from: day))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Calendar.app.isDate(day, inSameDayAs: selectedDate) ? .white : Theme.ink)
                                .frame(width: 34, height: 34)
                                .background {
                                    if Calendar.app.isDate(day, inSameDayAs: selectedDate) {
                                        Circle().fill(Theme.accentDeep)
                                    }
                                }
                            Text("\(orders.count)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(orders.isEmpty ? Theme.hairline : Theme.accent)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardSurface()
    }

    private var weekDays: [Date] {
        guard let interval = Calendar.app.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { Calendar.app.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Fmt.locale
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date).uppercased()
    }

    private var dayTasks: some View {
        let orders = store.orders(on: selectedDate)
        return VStack(spacing: 12) {
            SectionTitle(text: Fmt.dayTitle(selectedDate), accessory: "\(orders.count) pedidos")
            if orders.isEmpty {
                Text("Sin entregas programadas.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(orders) { order in
                NavigationLink {
                    OrderDetailView(orderID: order.id)
                } label: {
                    NavigationRowLabel(title: "\(order.clientName) · \(order.displayTitle)",
                                       subtitle: "\(taskLabel(order)) · \(Fmt.time(order.deliveryDate))",
                                       symbol: taskSymbol(order),
                                       tint: order.status.tint)
                }
                .buttonStyle(.plain)
            }
        }
        .cardSurface()
    }

    private func taskLabel(_ order: Order) -> String {
        switch order.status {
        case .confirmado, .porPreparar: return "Hornear"
        case .horneado: return "Rellenar y cubrir"
        case .decorando: return "Decorar"
        case .terminado: return "Entregar"
        default: return order.status.label
        }
    }

    private func taskSymbol(_ order: Order) -> String {
        switch order.status {
        case .confirmado, .porPreparar: return "flame"
        case .horneado: return "drop"
        case .decorando: return "paintbrush"
        case .terminado, .entregado: return "shippingbox"
        default: return "bubble.left"
        }
    }
}
