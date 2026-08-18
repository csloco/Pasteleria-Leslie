import SwiftUI

struct CatalogView: View {
    @Environment(AppStore.self) private var store
    @State private var editingProduct: CatalogProduct?
    @State private var isCreating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(CatalogCategory.allCases) { category in
                    let products = store.data.catalog.filter { $0.category == category }
                    if !products.isEmpty {
                        VStack(spacing: 10) {
                            SectionTitle(text: category.label, accessory: "\(products.count)")
                            ForEach(products) { product in
                                Button {
                                    editingProduct = product
                                } label: {
                                    HStack(spacing: 12) {
                                        photo(for: product)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(product.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(Theme.ink)
                                            Text(product.detail)
                                                .font(.caption)
                                                .foregroundStyle(Theme.secondaryInk)
                                                .lineLimit(2)
                                            HStack(spacing: 8) {
                                                Text(Fmt.money(product.basePrice, decimals: 0))
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(Theme.accentDeep)
                                                if product.servings > 0 {
                                                    Text("· \(product.servings) porciones")
                                                        .font(.caption2)
                                                        .foregroundStyle(Theme.secondaryInk)
                                                }
                                            }
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Theme.hairline)
                                    }
                                    .contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                                if product.id != products.last?.id {
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
        .navigationTitle("Catálogo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isCreating = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editingProduct) { product in
            CatalogEditorSheet(product: product)
        }
        .sheet(isPresented: $isCreating) {
            CatalogEditorSheet(product: CatalogProduct())
        }
    }

    private func photo(for product: CatalogProduct) -> some View {
        Color(Theme.blush)
            .frame(width: 58, height: 58)
            .overlay {
                if let url = URL(string: product.photoURL), !product.photoURL.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "photo")
                            .foregroundStyle(Theme.accent)
                    }
                    .allowsHitTesting(false)
                } else {
                    Image(systemName: "birthday.cake")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.accent)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(.rect(cornerRadius: 14))
    }
}

struct CatalogEditorSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CatalogProduct

    init(product: CatalogProduct) {
        _draft = State(initialValue: product)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Producto") {
                    TextField("Nombre", text: $draft.name)
                    Picker("Categoría", selection: $draft.category) {
                        ForEach(CatalogCategory.allCases) { category in
                            Text(category.label).tag(category)
                        }
                    }
                    TextField("Descripción", text: $draft.detail, axis: .vertical)
                        .lineLimit(1...4)
                    TextField("Foto (enlace)", text: $draft.photoURL)
                        .textInputAutocapitalization(.never)
                }
                Section("Detalles") {
                    LabeledContent("Precio base") {
                        TextField("0", value: $draft.basePrice, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    TextField("Tamaños disponibles", text: $draft.sizes)
                    TextField("Sabores y rellenos", text: $draft.flavors)
                    Stepper("Porciones · \(draft.servings)", value: $draft.servings, in: 0...200)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .navigationTitle(draft.name.isEmpty ? "Nuevo producto" : draft.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        store.upsert(product: draft)
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
