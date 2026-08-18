import SwiftUI

struct OrdersView: View {
    @Environment(AppStore.self) private var store

    @State private var search = ""
    @State private var range: DateRange = .today
    @State private var statusFilter: OrderStatus?
    @State private var isCreating = false

    enum DateRange: String, CaseIterable, Identifiable {
        case today = "Hoy"
        case week = "Esta semana"
        case all = "Todos"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ScreenHeader(title: "Pedidos de Instagram") {
                        Button {
                            isCreating = true
                        } label: {
                            Label("Nuevo", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.accentDeep)
                                .padding(.horizontal, 14)
                                .frame(height: 38)
                                .background(Theme.blush, in: .capsule)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)

                    searchRow
                    statusChips

                    if grouped.isEmpty {
                        EmptyStateView(symbol: "tray",
                                       title: "Sin pedidos",
                                       message: "Registra un pedido nuevo para verlo aquí.")
                    } else {
                        ForEach(grouped, id: \.title) { group in
                            VStack(spacing: 10) {
                                Text(group.title.uppercased())
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Theme.secondaryInk)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                VStack(spacing: 12) {
                                    ForEach(group.orders) { order in
                                        NavigationLink {
                                            OrderDetailView(orderID: order.id)
                                        } label: {
                                            OrderRow(order: order)
                                        }
                                        .buttonStyle(.plain)
                                        if order.id != group.orders.last?.id {
                                            Divider().overlay(Theme.hairline)
                                        }
                                    }
                                }
                                .cardSurface()
                            }
                        }
                    }
                    Color.clear.frame(height: 70)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .canvasBackground()
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                Button {
                    isCreating = true
                } label: {
                    Label("Registrar pedido", systemImage: "camera.aperture")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .background(
                    LinearGradient(colors: [Theme.canvas.opacity(0), Theme.canvas], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                )
            }
        }
        .sheet(isPresented: $isCreating) {
            OrderEditorView(order: Order(), isNew: true)
        }
    }

    private var searchRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.secondaryInk)
                TextField("Buscar cliente o pedido", text: $search)
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(Theme.surface, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.hairline, lineWidth: 1)
            }

            Picker("", selection: $range) {
                ForEach(DateRange.allCases) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            .labelsHidden()
            .tint(Theme.accentDeep)
            .padding(.horizontal, 10)
            .frame(height: 46)
            .background(Theme.surface, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.hairline, lineWidth: 1)
            }
        }
    }

    private var statusChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ChoiceChip(title: "Todos · \(rangeFiltered.count)", isSelected: statusFilter == nil) {
                    statusFilter = nil
                }
                ForEach(OrderStatus.allCases) { status in
                    let count = rangeFiltered.filter { $0.status == status }.count
                    if count > 0 {
                        ChoiceChip(title: "\(status.label) · \(count)", isSelected: statusFilter == status) {
                            statusFilter = statusFilter == status ? nil : status
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var rangeFiltered: [Order] {
        let calendar = Calendar.app
        return store.data.orders.filter { order in
            switch range {
            case .today:
                return calendar.isDateInToday(order.deliveryDate) || order.status.isOpen
            case .week:
                guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return true }
                return week.contains(order.deliveryDate)
            case .all:
                return true
            }
        }
    }

    private var filtered: [Order] {
        var list = rangeFiltered
        if let statusFilter {
            list = list.filter { $0.status == statusFilter }
        }
        let query = search.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            list = list.filter {
                $0.clientName.localizedStandardContains(query)
                    || $0.displayTitle.localizedStandardContains(query)
                    || $0.instagram.localizedStandardContains(query)
            }
        }
        return list.sorted { $0.deliveryDate < $1.deliveryDate }
    }

    private struct OrderGroup {
        let title: String
        let orders: [Order]
    }

    private var grouped: [OrderGroup] {
        let calendar = Calendar.app
        let groups = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.deliveryDate) }
        return groups.keys.sorted().map { day in
            let title: String
            if calendar.isDateInToday(day) { title = "Hoy" }
            else if calendar.isDateInTomorrow(day) { title = "Mañana" }
            else { title = Fmt.dayTitle(day) }
            return OrderGroup(title: title, orders: groups[day] ?? [])
        }
    }
}

/// Row shown in the orders inbox.
struct OrderRow: View {
    let order: Order

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(order.initials.isEmpty ? "?" : order.initials)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.accentDeep)
                .frame(width: 42, height: 42)
                .background(Theme.blush, in: .circle)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(order.clientName) · \(order.displayTitle)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                    Spacer(minLength: 6)
                    Text(Fmt.time(order.deliveryDate))
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                }
                HStack(spacing: 8) {
                    StatusPill(text: order.status.label, color: order.status.tint)
                    Text(order.status.isProduction ? "entrega \(Fmt.time(order.deliveryDate))" : Fmt.shortDay(order.deliveryDate))
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                }
                HStack(spacing: 12) {
                    Label(order.isPaid ? "Pagado" : "Saldo \(Fmt.money(order.balance, decimals: 0))",
                          systemImage: "creditcard")
                        .font(.caption)
                        .foregroundStyle(order.isPaid ? Theme.sage : Theme.gold)
                    Label(order.address.isEmpty ? "Recoge en tienda" : "Entrega a domicilio",
                          systemImage: "shippingbox")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                    if !order.attachments.isEmpty {
                        Label("\(order.attachments.count)", systemImage: "paperclip")
                            .font(.caption)
                            .foregroundStyle(Theme.accentDeep)
                            .accessibilityLabel("\(order.attachments.count) referencias adjuntas")
                    }
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.hairline)
                .padding(.top, 14)
        }
        .contentShape(.rect)
    }
}

#Preview {
    OrdersView()
        .environment(AppStore())
}
