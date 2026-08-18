import SwiftUI

struct InventoryView: View {
    @Environment(AppStore.self) private var store

    @State private var editingItem: InventoryItem?
    @State private var isCreating = false
    @State private var search = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !store.lowStockItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Alertas", accessory: "\(store.lowStockItems.count)")
                        ForEach(store.lowStockItems) { item in
                            Label("Quedan \(item.stockLabel) de \(item.name.lowercased())",
                                  systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardSurface()
                }

                ForEach(InventoryCategory.allCases) { category in
                    let items = filtered.filter { $0.category == category }
                    if !items.isEmpty {
                        VStack(spacing: 8) {
                            SectionTitle(text: category.label, accessory: "\(items.count)")
                            ForEach(items) { item in
                                Button { editingItem = item } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(Theme.ink)
                                            Text("\(item.stockLabel) · \(item.minimumLabel) · \(Fmt.money(item.pricePerUnit, decimals: 3))/\(item.unit.shortLabel)")
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
                                if item.id != items.last?.id {
                                    Divider().overlay(Theme.hairline)
                                }
                            }
                        }
                        .cardSurface()
                    }
                }
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .canvasBackground()
        .searchable(text: $search, prompt: "Buscar artículo")
        .navigationTitle("Inventario")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isCreating = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingItem) { item in
            InventoryEditorSheet(item: item)
        }
        .sheet(isPresented: $isCreating) {
            InventoryEditorSheet(item: InventoryItem(), isNew: true)
        }
    }

    private var filtered: [InventoryItem] {
        let query = search.trimmingCharacters(in: .whitespaces)
        let list = store.data.inventory.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        guard !query.isEmpty else { return list }
        return list.filter { $0.name.localizedStandardContains(query) }
    }
}
