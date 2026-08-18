import SwiftUI

struct MoreView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ScreenHeader(title: "Más", subtitle: "Todo tu taller en un solo lugar")
                        .padding(.top, 8)

                    VStack(spacing: 4) {
                        NavigationLink { RecipesView() } label: {
                            NavigationRowLabel(title: "Mis recetas",
                                               subtitle: "\(store.data.recipes.count) recetas base",
                                               symbol: "book.closed.fill")
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.hairline)
                        NavigationLink { InventoryView() } label: {
                            NavigationRowLabel(title: "Inventario",
                                               subtitle: "\(store.lowStockItems.count) artículos por reponer",
                                               symbol: "shippingbox.fill",
                                               tint: Theme.gold)
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.hairline)
                        NavigationLink { ShoppingListView() } label: {
                            NavigationRowLabel(title: "Lista de compras",
                                               subtitle: "Suma los pedidos de una fecha",
                                               symbol: "cart.fill",
                                               tint: Theme.sage)
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.hairline)
                        NavigationLink { ClientsView() } label: {
                            NavigationRowLabel(title: "Clientes",
                                               subtitle: "\(store.data.clients.count) registrados",
                                               symbol: "person.2.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    .cardSurface()

                    VStack(spacing: 4) {
                        NavigationLink { CostsView() } label: {
                            NavigationRowLabel(title: "Costos",
                                               subtitle: "Precio por gramo y márgenes",
                                               symbol: "banknote.fill",
                                               tint: Theme.gold)
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.hairline)
                        NavigationLink { StatsView() } label: {
                            NavigationRowLabel(title: "Estadísticas",
                                               subtitle: "Ventas, ganancia y sabores",
                                               symbol: "chart.bar.fill",
                                               tint: Theme.sage)
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.hairline)
                        NavigationLink { CatalogView() } label: {
                            NavigationRowLabel(title: "Catálogo",
                                               subtitle: "\(store.data.catalog.count) productos",
                                               symbol: "photo.on.rectangle.angled")
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.hairline)
                        NavigationLink { CalendarBoardView() } label: {
                            NavigationRowLabel(title: "Calendario de producción",
                                               subtitle: "Vista mensual y semanal",
                                               symbol: "calendar")
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.hairline)
                        NavigationLink { SettingsView() } label: {
                            NavigationRowLabel(title: "Configuración",
                                               subtitle: "Preferencias y datos",
                                               symbol: "gearshape.fill",
                                               tint: Theme.secondaryInk)
                        }
                        .buttonStyle(.plain)
                    }
                    .cardSurface()

                    if !store.data.savedCalculations.isEmpty {
                        VStack(spacing: 8) {
                            SectionTitle(text: "Cálculos guardados")
                            ForEach(store.data.savedCalculations.reversed()) { calculation in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(calculation.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Theme.ink)
                                        Text("\(calculation.spec.summaryLabel) · \(Fmt.length(calculation.spec.totalHeight, unit: calculation.spec.unit))")
                                            .font(.caption)
                                            .foregroundStyle(Theme.secondaryInk)
                                    }
                                    Spacer(minLength: 8)
                                    Text(Fmt.shortDay(calculation.createdAt))
                                        .font(.caption2)
                                        .foregroundStyle(Theme.secondaryInk)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .cardSurface()
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
    }
}

#Preview {
    MoreView()
        .environment(AppStore())
}
