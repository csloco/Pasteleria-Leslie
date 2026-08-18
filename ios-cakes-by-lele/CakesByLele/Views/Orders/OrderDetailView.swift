import SwiftUI

struct OrderDetailView: View {
    @Environment(AppStore.self) private var store
    let orderID: UUID

    @State private var isEditing = false
    @State private var isAddingReference = false
    @State private var viewerAttachmentID: UUID?

    private var order: Order? {
        store.data.orders.first { $0.id == orderID }
    }

    var body: some View {
        ScrollView {
            if let order {
                VStack(spacing: 16) {
                    if !order.photoAttachments.isEmpty {
                        ReferenceHeroGallery(photos: order.photoAttachments) { attachment in
                            viewerAttachmentID = attachment.id
                        }
                    }
                    VStack(spacing: 16) {
                        headerCard(order)
                        OrderReferencesCard(order: order,
                                            onAdd: { isAddingReference = true },
                                            onOpen: { viewerAttachmentID = $0.id })
                        statusCard(order)
                        cakeCard(order)
                        paymentCard(order)
                        if !order.design.isEmpty || !order.dedication.isEmpty || !order.notes.isEmpty {
                            notesCard(order)
                        }
                        productionCard(order)
                    }
                    .padding(.horizontal, 16)
                    Color.clear.frame(height: 12)
                }
                .padding(.top, order.photoAttachments.isEmpty ? 8 : 0)
                .padding(.bottom, 24)
            } else {
                EmptyStateView(symbol: "tray",
                               title: "Pedido no disponible",
                               message: "Este pedido ya no existe.")
                    .padding(16)
            }
        }
        .scrollIndicators(.hidden)
        .canvasBackground()
        .navigationTitle(order?.clientName ?? "Pedido")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") { isEditing = true }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let order, order.status.isProduction || !order.materials.isEmpty {
                Button {
                    store.openProductionTicket(for: order.id)
                } label: {
                    Label("Abrir ficha de producción", systemImage: "list.clipboard")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .background(
                    LinearGradient(colors: [Theme.canvas.opacity(0), Theme.canvas],
                                   startPoint: .top,
                                   endPoint: .bottom)
                        .ignoresSafeArea()
                )
            }
        }
        .sheet(isPresented: $isEditing) {
            if let order {
                OrderEditorView(order: order, isNew: false)
            }
        }
        .sheet(isPresented: $isAddingReference) {
            AddAttachmentSheet(orderID: orderID, clientName: order?.clientName ?? "")
        }
        .fullScreenCover(item: $viewerAttachmentID) { id in
            AttachmentViewerView(orderID: orderID, startID: id)
        }
    }

    private func headerCard(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(order.initials.isEmpty ? "?" : order.initials)
                    .font(.headline)
                    .foregroundStyle(Theme.accentDeep)
                    .frame(width: 52, height: 52)
                    .background(Theme.blush, in: .circle)
                VStack(alignment: .leading, spacing: 3) {
                    Text(order.clientName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.ink)
                    if !order.instagram.isEmpty {
                        Text(order.instagram)
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                    if !order.phone.isEmpty {
                        Text(order.phone)
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                }
                Spacer(minLength: 0)
                StatusPill(text: order.status.label, color: order.status.tint)
            }
            Divider().overlay(Theme.hairline)
            HStack {
                Label(Fmt.dayTitle(order.deliveryDate), systemImage: "calendar")
                Spacer(minLength: 8)
                Label(Fmt.time(order.deliveryDate), systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(Theme.secondaryInk)
        }
        .cardSurface()
    }

    private func statusCard(_ order: Order) -> some View {
        VStack(spacing: 10) {
            SectionTitle(text: "Estado del pedido")
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(OrderStatus.allCases) { status in
                        ChoiceChip(title: status.label, isSelected: order.status == status) {
                            updateStatus(status)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .cardSurface()
    }

    private func cakeCard(_ order: Order) -> some View {
        let result = store.calculate(spec: order.spec, recipeID: order.recipeID)
        return VStack(spacing: 2) {
            SectionTitle(text: "Pastel", accessory: order.flavor)
                .padding(.bottom, 6)
            ResultRow(title: "Tamaño", value: order.spec.summaryLabel, symbol: "ruler")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Pisos · Capas · Rellenos",
                      value: "\(order.spec.tierCount) · \(order.spec.tiers.first?.layers.count ?? 0) · \(order.spec.tiers.first?.fillings.count ?? 0)",
                      symbol: "square.stack.3d.up")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Altura total",
                      value: "\(Fmt.number(order.spec.totalHeight * 2.54, decimals: 1)) cm",
                      symbol: "arrow.up.and.down")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Porciones", value: "\(result.servings)", symbol: "person.2")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Masa total", value: Fmt.grams(result.batterGrams.rounded()), symbol: "birthday.cake")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Costo estimado", value: Fmt.money(result.productionCost), symbol: "banknote", tint: Theme.gold)
        }
        .cardSurface()
    }

    private func paymentCard(_ order: Order) -> some View {
        VStack(spacing: 2) {
            SectionTitle(text: "Pago y entrega")
                .padding(.bottom, 6)
            ResultRow(title: "Precio", value: Fmt.money(order.price, decimals: 0), symbol: "tag")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Anticipo", value: Fmt.money(order.deposit, decimals: 0), symbol: "arrow.down.circle")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Envío", value: Fmt.money(order.shippingCost, decimals: 0), symbol: "shippingbox")
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Saldo pendiente",
                      value: order.isPaid ? "Pagado" : Fmt.money(order.balance, decimals: 0),
                      symbol: "creditcard",
                      tint: order.isPaid ? Theme.sage : Theme.gold,
                      emphasized: true)
            if !order.address.isEmpty {
                Divider().overlay(Theme.hairline)
                ResultRow(title: "Dirección", value: order.address, symbol: "mappin.and.ellipse")
            }
        }
        .cardSurface()
    }

    private func notesCard(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Diseño y notas")
            if !order.design.isEmpty {
                labeled("Diseño solicitado", order.design)
            }
            if !order.dedication.isEmpty {
                labeled("Dedicatoria", order.dedication)
            }
            if !order.notes.isEmpty {
                labeled("Notas", order.notes)
            }
        }
        .cardSurface()
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func productionCard(_ order: Order) -> some View {
        VStack(spacing: 12) {
            SectionTitle(text: "Ficha de producción",
                         accessory: order.materials.isEmpty ? nil : "\(order.readyMaterials)/\(order.materials.count) listos")
            if order.materials.isEmpty {
                Text("Genera la ficha para obtener masa, ingredientes, relleno y cobertura calculados.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ProgressView(value: order.checklistProgress)
                    .tint(Theme.accentDeep)
            }
            Button {
                store.refreshProductionTicket(orderID: order.id)
            } label: {
                Label(order.materials.isEmpty ? "Generar ficha de producción" : "Actualizar ficha",
                      systemImage: "doc.text")
            }
            .buttonStyle(order.materials.isEmpty ? AnyButtonStyle(PrimaryButtonStyle()) : AnyButtonStyle(SoftButtonStyle()))
        }
        .cardSurface()
    }

    private func updateStatus(_ status: OrderStatus) {
        guard var order else { return }
        order.status = status
        if status.isProduction && order.materials.isEmpty {
            store.upsert(order: order)
            store.refreshProductionTicket(orderID: order.id)
        } else {
            store.upsert(order: order)
        }
    }
}

/// Small type eraser so a button style can be chosen at runtime.
struct AnyButtonStyle: ButtonStyle {
    private let makeBodyClosure: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        makeBodyClosure = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        makeBodyClosure(configuration)
    }
}
