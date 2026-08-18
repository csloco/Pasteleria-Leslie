import SwiftUI

struct RecipesView: View {
    @Environment(AppStore.self) private var store
    @State private var editingRecipe: Recipe?
    @State private var isCreating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(store.data.recipes) { recipe in
                    Button {
                        editingRecipe = recipe
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                Text(recipe.emoji)
                                    .font(.title2)
                                    .frame(width: 46, height: 46)
                                    .background(Theme.blush, in: .circle)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recipe.name)
                                        .font(.headline)
                                        .foregroundStyle(Theme.ink)
                                    Text(recipe.referenceLabel)
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
                                Label("\(Fmt.number(recipe.yieldGrams)) g de mezcla", systemImage: "scalemass")
                                Spacer(minLength: 8)
                                Label("\(recipe.ovenTemperature)° · \(recipe.bakeMinutes) min", systemImage: "flame")
                            }
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                            Text("\(recipe.ingredients.count) ingredientes registrados")
                                .font(.caption)
                                .foregroundStyle(Theme.accentDeep)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .cardSurface()
                }

                if store.data.recipes.isEmpty {
                    EmptyStateView(symbol: "book.closed",
                                   title: "Sin recetas",
                                   message: "Registra tu primera receta base para escalar cantidades.")
                }
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .canvasBackground()
        .navigationTitle("Mis recetas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isCreating = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editingRecipe) { recipe in
            RecipeEditorView(recipe: recipe, isNew: false)
        }
        .sheet(isPresented: $isCreating) {
            RecipeEditorView(recipe: Recipe(name: "", ingredients: [RecipeIngredient()]), isNew: true)
        }
    }
}

/// Full recipe editor: reference pan, yield, ingredients and baking notes.
struct RecipeEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Recipe
    private let isNew: Bool

    init(recipe: Recipe, isNew: Bool) {
        _draft = State(initialValue: recipe)
        self.isNew = isNew
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Receta") {
                    TextField("Nombre", text: $draft.name)
                    TextField("Emoji", text: $draft.emoji)
                    TextField("Foto (enlace)", text: $draft.photoURL)
                        .textInputAutocapitalization(.never)
                }

                Section("Referencia de escalado") {
                    Picker("Forma del molde", selection: $draft.shape) {
                        ForEach(CakeShape.allCases) { shape in
                            Text(shape.label).tag(shape)
                        }
                    }
                    LabeledContent(draft.shape.primaryLabel) {
                        TextField("0", value: $draft.panPrimarySize, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if draft.shape == .rectangular {
                        LabeledContent("Largo") {
                            TextField("0", value: $draft.panSecondarySize, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    LabeledContent("Altura de referencia (pulg)") {
                        TextField("0", value: $draft.referenceSpongeHeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Mezcla que produce (g)") {
                        TextField("0", value: $draft.yieldGrams, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Volumen de referencia",
                                   value: "\(Fmt.number(draft.referenceVolume)) pulg³")
                        .foregroundStyle(Theme.secondaryInk)
                }

                Section("Ingredientes") {
                    ForEach($draft.ingredients) { $ingredient in
                        VStack(spacing: 6) {
                            TextField("Ingrediente", text: $ingredient.name)
                            HStack {
                                TextField("Cantidad", value: $ingredient.quantity, format: .number)
                                    .keyboardType(.decimalPad)
                                Picker("", selection: $ingredient.unit) {
                                    ForEach(MeasureUnit.allCases) { unit in
                                        Text(unit.label).tag(unit)
                                    }
                                }
                                .labelsHidden()
                            }
                            Picker("Inventario", selection: $ingredient.inventoryItemID) {
                                Text("Sin relación").tag(Optional<UUID>.none)
                                ForEach(store.data.inventory) { item in
                                    Text(item.name).tag(Optional(item.id))
                                }
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { draft.ingredients.remove(atOffsets: $0) }

                    Button {
                        draft.ingredients.append(RecipeIngredient())
                    } label: {
                        Label("Añadir ingrediente", systemImage: "plus.circle")
                    }
                }

                Section("Horneado") {
                    Stepper("Temperatura · \(draft.ovenTemperature)°C", value: $draft.ovenTemperature, in: 100...250, step: 5)
                    Stepper("Tiempo · \(draft.bakeMinutes) min", value: $draft.bakeMinutes, in: 10...120, step: 5)
                    TextField("Procedimiento", text: $draft.procedure, axis: .vertical)
                        .lineLimit(2...8)
                    TextField("Notas", text: $draft.notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            store.deleteRecipe(id: draft.id)
                            dismiss()
                        } label: {
                            Label("Eliminar receta", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .navigationTitle(isNew ? "Nueva receta" : draft.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        store.upsert(recipe: draft)
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
