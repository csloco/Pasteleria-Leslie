import SwiftUI

struct ClientsView: View {
    @Environment(AppStore.self) private var store
    @State private var search = ""
    @State private var editingClient: Client?
    @State private var isCreating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(filtered) { client in
                    let history = orders(for: client)
                    Button {
                        editingClient = client
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                Text(initials(client.name))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Theme.accentDeep)
                                    .frame(width: 42, height: 42)
                                    .background(Theme.blush, in: .circle)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(client.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.ink)
                                    Text([client.instagram, client.phone].filter { !$0.isEmpty }.joined(separator: " · "))
                                        .font(.caption)
                                        .foregroundStyle(Theme.secondaryInk)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.hairline)
                            }
                            Divider().overlay(Theme.hairline)
                            HStack {
                                Label("\(history.count) pedidos", systemImage: "bag")
                                Spacer(minLength: 8)
                                Label(Fmt.money(history.reduce(0) { $0 + $1.price }, decimals: 0), systemImage: "banknote")
                            }
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                            if let last = history.first {
                                Text("Último pedido · \(Fmt.shortDay(last.deliveryDate)) · \(last.displayTitle)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.accentDeep)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .cardSurface()
                }

                if filtered.isEmpty {
                    EmptyStateView(symbol: "person.2",
                                   title: "Sin clientes",
                                   message: "Los clientes se registran automáticamente al crear pedidos.")
                }
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .canvasBackground()
        .searchable(text: $search, prompt: "Buscar cliente")
        .navigationTitle("Clientes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isCreating = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editingClient) { client in
            ClientEditorSheet(client: client)
        }
        .sheet(isPresented: $isCreating) {
            ClientEditorSheet(client: Client())
        }
    }

    private var filtered: [Client] {
        let query = search.trimmingCharacters(in: .whitespaces)
        let list = store.data.clients.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        guard !query.isEmpty else { return list }
        return list.filter { $0.name.localizedStandardContains(query) || $0.instagram.localizedStandardContains(query) }
    }

    private func orders(for client: Client) -> [Order] {
        store.data.orders
            .filter { $0.clientName.localizedCaseInsensitiveCompare(client.name) == .orderedSame }
            .sorted { $0.deliveryDate > $1.deliveryDate }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }
}

struct ClientEditorSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Client

    init(client: Client) {
        _draft = State(initialValue: client)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos") {
                    TextField("Nombre", text: $draft.name)
                    TextField("Instagram", text: $draft.instagram)
                        .textInputAutocapitalization(.never)
                    TextField("Teléfono", text: $draft.phone)
                        .keyboardType(.phonePad)
                    TextField("Pastel favorito", text: $draft.favoriteFlavor)
                }
                Section("Notas") {
                    TextField("Notas", text: $draft.notes, axis: .vertical)
                        .lineLimit(1...5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .navigationTitle(draft.name.isEmpty ? "Nuevo cliente" : draft.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        store.upsert(client: draft)
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
