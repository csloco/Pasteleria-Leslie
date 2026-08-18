import SwiftUI

/// The heart of the app: measurements, ingredients and costs together.
struct CalculatorView: View {
    @Environment(AppStore.self) private var store

    @State private var spec = CakeSpec()
    @State private var recipeID: UUID?
    @State private var selectedTierIndex: Int = 0
    @State private var isSavingCalculation = false
    @State private var calculationName = ""
    @State private var generatedOrder: Order?
    @State private var didLoadDefaults = false

    private var result: CalculationResult {
        store.calculate(spec: spec, recipeID: recipeID)
    }

    private var activeTier: CakeTier? {
        spec.tiers.indices.contains(selectedTierIndex) ? spec.tiers[selectedTierIndex] : spec.tiers.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ScreenHeader(title: "Calculadora de pastel",
                                 subtitle: "Medidas, ingredientes y costos juntos")
                        .padding(.top, 8)

                    baseCard
                    tierSelectorCard
                    if activeTier != nil {
                        SpongeLayersCard(spec: $spec,
                                         tierIndex: clampedIndex,
                                         recipe: currentRecipe)
                        FillingsCard(spec: $spec, tierIndex: clampedIndex)
                    }
                    elevationCard
                    resultsCard
                    ingredientsCard
                    coatingCard
                    actionsRow
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .canvasBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear(perform: loadDefaults)
        .alert("Guardar cálculo", isPresented: $isSavingCalculation) {
            TextField("Nombre del cálculo", text: $calculationName)
            Button("Cancelar", role: .cancel) {}
            Button("Guardar") { saveCalculation() }
        } message: {
            Text("Se guardará la configuración actual con todas sus capas y rellenos.")
        }
        .sheet(item: $generatedOrder) { order in
            OrderEditorView(order: order, isNew: true)
        }
    }

    private var clampedIndex: Int {
        min(max(selectedTierIndex, 0), max(spec.tiers.count - 1, 0))
    }

    private var currentRecipe: Recipe? {
        store.recipe(id: recipeID) ?? store.defaultRecipe
    }

    private func loadDefaults() {
        guard !didLoadDefaults else { return }
        didLoadDefaults = true
        recipeID = store.defaultRecipe?.id
        spec.unit = store.data.defaultUnit
        spec.servingSize = store.data.defaultServingSize
        spec.wastePercent = store.data.defaultWastePercent
        spec.roundEggs = store.data.roundEggs
        for index in spec.tiers.indices {
            spec.tiers[index].recipeID = recipeID
        }
    }

    // MARK: - Base configuration

    private var baseCard: some View {
        VStack(spacing: 2) {
            configRow(symbol: "book.closed", title: "Receta base") {
                Picker("", selection: Binding(get: { recipeID ?? store.defaultRecipe?.id }, set: { newValue in
                    recipeID = newValue
                    for index in spec.tiers.indices where spec.tiers[index].recipeID == nil {
                        spec.tiers[index].recipeID = newValue
                    }
                })) {
                    ForEach(store.data.recipes) { recipe in
                        Text("\(recipe.emoji) \(recipe.name)").tag(Optional(recipe.id))
                    }
                }
                .labelsHidden()
                .tint(Theme.accentDeep)
            }
            Divider().overlay(Theme.hairline)
            configRow(symbol: "circle", title: "Forma") {
                Picker("", selection: Binding(get: { activeTier?.shape ?? .round }, set: { newValue in
                    updateActiveTier { $0.shape = newValue }
                })) {
                    ForEach(CakeShape.allCases) { shape in
                        Text(shape.label).tag(shape)
                    }
                }
                .labelsHidden()
                .tint(Theme.accentDeep)
            }
            Divider().overlay(Theme.hairline)
            configRow(symbol: "square.stack.3d.up", title: "Pisos") {
                Stepper(value: Binding(get: { spec.tiers.count }, set: { setTierCount($0) }), in: 1...4) {
                    Text("\(spec.tiers.count)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                }
                .labelsHidden()
                .fixedSize()
            }
            Divider().overlay(Theme.hairline)
            configRow(symbol: "ruler", title: "Unidad") {
                Picker("", selection: $spec.unit) {
                    Text("pulgadas").tag(LengthUnit.inches)
                    Text("cm").tag(LengthUnit.centimeters)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
        }
        .cardSurface()
    }

    private func configRow<Content: View>(symbol: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accentDeep)
                .frame(width: 30, height: 30)
                .background(Theme.blush, in: .rect(cornerRadius: 9))
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 8)
            content()
        }
        .padding(.vertical, 5)
    }

    // MARK: - Tier selector

    private var tierSelectorCard: some View {
        VStack(spacing: 12) {
            HStack {
                SectionTitle(text: "Editando · \(CakeSpec.tierName(index: clampedIndex, total: spec.tiers.count))")
                Spacer(minLength: 0)
            }
            if spec.tiers.count > 1 {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(Array(spec.tiers.enumerated()), id: \.element.id) { index, tier in
                            ChoiceChip(title: "\(CakeSpec.tierName(index: index, total: spec.tiers.count)) · \(tier.sizeLabel)",
                                       isSelected: index == clampedIndex) {
                                selectedTierIndex = index
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            if let tier = activeTier {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tier.shape.primaryLabel)
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                        HStack(spacing: 8) {
                            NumberField(title: tier.shape.primaryLabel,
                                        value: Binding(get: { spec.unit.fromInches(tier.primarySize) },
                                                       set: { newValue in updateActiveTier { $0.primarySize = spec.unit.toInches(newValue) } }),
                                        suffix: spec.unit == .inches ? "\"" : "cm")
                            if tier.shape == .rectangular {
                                NumberField(title: "Largo",
                                            value: Binding(get: { spec.unit.fromInches(tier.secondarySize) },
                                                           set: { newValue in updateActiveTier { $0.secondarySize = spec.unit.toInches(newValue) } }),
                                            suffix: spec.unit == .inches ? "\"" : "cm")
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Altura del piso")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                        Text(Fmt.length(tier.totalHeight, unit: spec.unit))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.accentDeep)
                            .monospacedDigit()
                    }
                }

                if tier.shape == .round {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach([4.0, 5, 6, 7, 8, 9, 10, 12], id: \.self) { size in
                                ChoiceChip(title: "\(Fmt.number(size))\"",
                                           isSelected: abs(tier.primarySize - size) < 0.01) {
                                    updateActiveTier { $0.primarySize = size }
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Elevation + heights

    private var elevationCard: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Altura del piso · \(Fmt.length(activeTier?.totalHeight ?? 0, unit: spec.unit))")
                    .font(.headline)
                    .foregroundStyle(Theme.accentDeep)
                Text("Altura total · \(Fmt.length(spec.totalHeight, unit: spec.unit))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(activeTier?.layers.count ?? 0) bizcochos · \(activeTier?.fillings.count ?? 0) rellenos")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
                Text("\(Fmt.number(spec.totalHeight * 2.54, decimals: 1)) cm en total")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }
            Spacer(minLength: 0)
            CakeElevationView(spec: spec, highlightedTierID: activeTier?.id)
                .frame(width: 150, height: 130)
        }
        .cardSurface()
    }

    // MARK: - Results

    private var resultsCard: some View {
        let result = result
        return VStack(spacing: 2) {
            SectionTitle(text: "Resultados", accessory: currentRecipe?.name)
                .padding(.bottom, 6)
            ResultRow(title: "Volumen recalculado",
                      value: "\(Fmt.number(result.totalVolume)) pulg³",
                      symbol: "cube",
                      tint: Theme.accent)
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Masa total",
                      value: Fmt.grams(result.batterGrams.rounded()),
                      symbol: "birthday.cake",
                      tint: Theme.accentDeep,
                      emphasized: true)
            Divider().overlay(Theme.hairline)
            ForEach(result.tiers) { tier in
                ResultRow(title: spec.tiers.count > 1 ? "Masa por molde · \(tier.name)" : "Masa por molde",
                          value: "\(Fmt.number(tier.batterPerMold.rounded())) g × \(tier.moldCount)",
                          symbol: "circle.grid.2x2",
                          tint: Theme.gold)
                Divider().overlay(Theme.hairline)
            }
            ResultRow(title: "Relleno total",
                      value: Fmt.grams(result.fillingGrams.rounded()),
                      symbol: "drop.fill",
                      tint: Theme.accent)
            Divider().overlay(Theme.hairline)
            HStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.sage)
                    .frame(width: 30, height: 30)
                    .background(Theme.sage.opacity(0.13), in: .rect(cornerRadius: 9))
                Text("Porciones")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                Picker("", selection: $spec.servingSize) {
                    ForEach(ServingSize.allCases) { size in
                        Text(size.label).tag(size)
                    }
                }
                .labelsHidden()
                .tint(Theme.accentDeep)
                Text("\(result.servings)")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Theme.accentDeep)
            }
            .padding(.vertical, 6)
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Costo de producción",
                      value: Fmt.money(result.productionCost),
                      symbol: "banknote",
                      tint: Theme.accentDeep,
                      emphasized: true)
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Precio sugerido",
                      value: Fmt.money(result.suggestedPrice, decimals: 0),
                      symbol: "tag",
                      tint: Theme.sage)
        }
        .cardSurface()
    }

    // MARK: - Ingredients

    private var ingredientsCard: some View {
        let result = result
        return VStack(spacing: 8) {
            HStack {
                SectionTitle(text: "Ingredientes necesarios")
                Spacer(minLength: 0)
                Toggle("", isOn: $spec.roundEggs)
                    .labelsHidden()
                    .tint(Theme.accentDeep)
            }
            Text(spec.roundEggs ? "Unidades redondeadas al entero más cercano" : "Se muestran unidades exactas")
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
                .frame(maxWidth: .infinity, alignment: .leading)

            if result.ingredients.isEmpty {
                Text("Selecciona una receta base con ingredientes registrados.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(result.ingredients) { ingredient in
                    HStack {
                        Text(ingredient.name)
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink)
                        Spacer(minLength: 8)
                        Text(ingredient.quantityLabel)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.ink)
                        Text(Fmt.money(ingredient.cost))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Theme.secondaryInk)
                            .frame(width: 62, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                    if ingredient.id != result.ingredients.last?.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Coating

    private var coatingCard: some View {
        let result = result
        return VStack(spacing: 10) {
            SectionTitle(text: "Cobertura")
            Picker("Cobertura", selection: $spec.coating) {
                ForEach(CoatingKind.allCases) { kind in
                    Text(kind.label).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            ResultRow(title: "Cantidad calculada", value: Fmt.grams(result.coatingBase.rounded()))
            Divider().overlay(Theme.hairline)
            HStack {
                Text("Margen por desperdicio")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                Stepper(value: $spec.wastePercent, in: 0...0.5, step: 0.05) {
                    Text(Fmt.percent(spec.wastePercent))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.accentDeep)
                }
                .labelsHidden()
                .fixedSize()
                Text(Fmt.grams(result.coatingWaste.rounded()))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Theme.secondaryInk)
            }
            Divider().overlay(Theme.hairline)
            ResultRow(title: "Total a preparar",
                      value: Fmt.grams(result.coatingTotal.rounded()),
                      emphasized: true)
        }
        .cardSurface()
    }

    // MARK: - Actions

    private var actionsRow: some View {
        HStack(spacing: 12) {
            Button {
                calculationName = "\(currentRecipe?.name ?? "Pastel") \(activeTier?.sizeLabel ?? "")"
                isSavingCalculation = true
            } label: {
                Label("Guardar cálculo", systemImage: "bookmark")
            }
            .buttonStyle(SoftButtonStyle())

            Button {
                generateTicket()
            } label: {
                Label("Generar ficha", systemImage: "doc.text")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    // MARK: - Mutations

    private func updateActiveTier(_ transform: (inout CakeTier) -> Void) {
        guard spec.tiers.indices.contains(clampedIndex) else { return }
        var tier = spec.tiers[clampedIndex]
        transform(&tier)
        tier.normalizeFillings()
        spec.tiers[clampedIndex] = tier
    }

    private func setTierCount(_ count: Int) {
        let target = max(1, min(count, 4))
        while spec.tiers.count > target { spec.tiers.removeLast() }
        while spec.tiers.count < target {
            var newTier = spec.tiers.last ?? CakeTier()
            newTier.id = UUID()
            newTier.primarySize += 2
            newTier.layers = newTier.layers.map { SpongeLayer(height: $0.height) }
            newTier.fillings = newTier.fillings.map { FillingLayer(kind: $0.kind, customName: $0.customName, thickness: $0.thickness) }
            newTier.recipeID = recipeID
            spec.tiers.append(newTier)
        }
        selectedTierIndex = min(selectedTierIndex, spec.tiers.count - 1)
    }

    private func saveCalculation() {
        let name = calculationName.trimmingCharacters(in: .whitespaces)
        store.data.savedCalculations.append(SavedCalculation(name: name.isEmpty ? "Cálculo" : name,
                                                             spec: spec,
                                                             recipeID: recipeID))
    }

    private func generateTicket() {
        let result = result
        let recipe = currentRecipe
        var order = Order()
        order.spec = spec
        order.recipeID = recipeID
        order.flavor = recipe?.name ?? ""
        order.cakeTitle = "\(recipe?.name ?? "Pastel") \(activeTier?.sizeLabel ?? "")"
        order.status = .confirmado
        order.price = result.suggestedPrice
        order.materials = CakeCalculator.materials(from: result, spec: spec, recipeName: recipe?.name ?? "pastel")
        order.checklist = CakeCalculator.checklist(from: result, spec: spec)
        generatedOrder = order
    }
}

#Preview {
    CalculatorView()
        .environment(AppStore())
}
