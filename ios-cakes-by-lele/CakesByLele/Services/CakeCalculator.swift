import Foundation

nonisolated struct ScaledIngredient: Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: MeasureUnit
    var cost: Double
    var inventoryItemID: UUID?

    var quantityLabel: String {
        unit == .unit
            ? "\(Fmt.number(quantity, decimals: quantity.rounded() == quantity ? 0 : 1)) \(quantity == 1 ? "unidad" : "unidades")"
            : "\(Fmt.number(quantity)) \(unit.shortLabel)"
    }
}

nonisolated struct FillingPortion: Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var thickness: Double
    var grams: Double
}

nonisolated struct TierResult: Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var sizeLabel: String
    var area: Double
    var spongeVolume: Double
    var spongeHeight: Double
    var fillingHeight: Double
    var totalHeight: Double
    var scaleFactor: Double
    var batterGrams: Double
    var moldCount: Int
    var batterPerMold: Double
    var ingredients: [ScaledIngredient]
    var fillings: [FillingPortion]
    var fillingGrams: Double
    var coatingGrams: Double
    var servings: Int
    var ingredientCost: Double
    var fillingCost: Double
}

nonisolated struct CalculationResult: Hashable, Sendable {
    var tiers: [TierResult] = []
    var totalHeightInches: Double = 0
    var totalVolume: Double = 0
    var batterGrams: Double = 0
    var ingredients: [ScaledIngredient] = []
    var fillingGrams: Double = 0
    var coatingBase: Double = 0
    var coatingWaste: Double = 0
    var coatingTotal: Double = 0
    var servings: Int = 0
    var ingredientCost: Double = 0
    var fillingCost: Double = 0
    var coatingCost: Double = 0

    var productionCost: Double { ingredientCost + fillingCost + coatingCost }
    /// Suggested retail price using a 3.2x production markup, rounded to the nearest 5.
    var suggestedPrice: Double { ((productionCost * 3.2) / 5).rounded() * 5 }
}

/// Pure math engine: scales a base recipe by volume and derives every production number.
nonisolated enum CakeCalculator {
    static let cubicInchToCubicCM = 16.3871
    static let squareInchToSquareCM = 6.4516

    static func calculate(spec: CakeSpec,
                          defaultRecipe: Recipe?,
                          recipes: [Recipe],
                          inventory: [InventoryItem],
                          fillingCostPerGram: Double = 0.032,
                          coatingCostPerGram: Double = 0.038) -> CalculationResult {
        var result = CalculationResult()
        var aggregated: [String: ScaledIngredient] = [:]

        for (index, tier) in spec.tiers.enumerated() {
            let recipe = recipes.first { $0.id == tier.recipeID } ?? defaultRecipe
            let tierResult = calculateTier(tier: tier,
                                           name: CakeSpec.tierName(index: index, total: spec.tiers.count),
                                           recipe: recipe,
                                           spec: spec,
                                           inventory: inventory,
                                           fillingCostPerGram: fillingCostPerGram)
            result.tiers.append(tierResult)
            result.batterGrams += tierResult.batterGrams
            result.fillingGrams += tierResult.fillingGrams
            result.coatingBase += tierResult.coatingGrams
            result.servings += tierResult.servings
            result.totalVolume += tierResult.spongeVolume
            result.ingredientCost += tierResult.ingredientCost
            result.fillingCost += tierResult.fillingCost

            for ingredient in tierResult.ingredients {
                let key = ingredient.name.lowercased() + ingredient.unit.rawValue
                if var existing = aggregated[key] {
                    existing.quantity += ingredient.quantity
                    existing.cost += ingredient.cost
                    aggregated[key] = existing
                } else {
                    aggregated[key] = ingredient
                }
            }
        }

        result.totalHeightInches = spec.totalHeight
        result.coatingWaste = result.coatingBase * spec.wastePercent
        result.coatingTotal = result.coatingBase + result.coatingWaste
        result.coatingCost = result.coatingTotal * coatingCostPerGram

        var list = Array(aggregated.values)
        if spec.roundEggs {
            list = list.map { ingredient in
                guard ingredient.unit.isCountable else { return ingredient }
                var rounded = ingredient
                rounded.quantity = ingredient.quantity.rounded(.up)
                return rounded
            }
        }
        result.ingredients = list.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return result
    }

    static func calculateTier(tier: CakeTier,
                              name: String,
                              recipe: Recipe?,
                              spec: CakeSpec,
                              inventory: [InventoryItem],
                              fillingCostPerGram: Double) -> TierResult {
        let area = tier.area
        let spongeVolume = tier.spongeVolume
        let referenceVolume = recipe?.referenceVolume ?? 0
        let scale = referenceVolume > 0 ? spongeVolume / referenceVolume : 0
        let batter = (recipe?.yieldGrams ?? 0) * scale
        let moldCount = max(tier.layers.count, 1)

        var ingredients: [ScaledIngredient] = []
        var ingredientCost: Double = 0
        for item in recipe?.ingredients ?? [] {
            let quantity = item.quantity * scale
            let unitPrice = price(for: item, inventory: inventory)
            let cost = quantity * unitPrice
            ingredientCost += cost
            ingredients.append(ScaledIngredient(id: item.id,
                                                name: item.name,
                                                quantity: quantity,
                                                unit: item.unit,
                                                cost: cost,
                                                inventoryItemID: item.inventoryItemID))
        }

        var fillings: [FillingPortion] = []
        var fillingGrams: Double = 0
        for filling in tier.fillings {
            let grams = area * filling.thickness * filling.kind.gramsPerCubicInch
            fillingGrams += grams
            fillings.append(FillingPortion(id: filling.id,
                                           name: filling.displayName,
                                           thickness: filling.thickness,
                                           grams: grams))
        }

        let coating = coatingGrams(tier: tier, kind: spec.coating)
        let servingsCount = servings(tier: tier, size: spec.servingSize)

        return TierResult(id: tier.id,
                          name: name,
                          sizeLabel: tier.sizeLabel,
                          area: area,
                          spongeVolume: spongeVolume,
                          spongeHeight: tier.spongeHeight,
                          fillingHeight: tier.fillingHeight,
                          totalHeight: tier.totalHeight,
                          scaleFactor: scale,
                          batterGrams: batter,
                          moldCount: moldCount,
                          batterPerMold: batter / Double(moldCount),
                          ingredients: ingredients,
                          fillings: fillings,
                          fillingGrams: fillingGrams,
                          coatingGrams: coating,
                          servings: servingsCount,
                          ingredientCost: ingredientCost,
                          fillingCost: fillingGrams * fillingCostPerGram)
    }

    /// Coating covers the top face plus the sides of the tier.
    static func coatingGrams(tier: CakeTier, kind: CoatingKind) -> Double {
        let topArea = tier.area
        let sideArea = tier.perimeter * tier.totalHeight
        let squareCentimeters = (topArea + sideArea) * squareInchToSquareCM
        return squareCentimeters * kind.gramsPerSquareCentimeter
    }

    /// Servings scale with the footprint and with how tall the cake is (4" reference).
    static func servings(tier: CakeTier, size: ServingSize) -> Int {
        guard tier.totalHeight > 0 else { return 0 }
        let heightFactor = tier.totalHeight / 4.0
        let raw = (tier.area / size.footprintSquareInches) * heightFactor
        return max(Int(raw.rounded()), 0)
    }

    static func price(for ingredient: RecipeIngredient, inventory: [InventoryItem]) -> Double {
        if let id = ingredient.inventoryItemID, let item = inventory.first(where: { $0.id == id }) {
            return item.pricePerUnit
        }
        if let item = inventory.first(where: { $0.name.localizedCaseInsensitiveCompare(ingredient.name) == .orderedSame }) {
            return item.pricePerUnit
        }
        return 0
    }

    /// Builds the editable material list used by the production ticket.
    static func materials(from result: CalculationResult,
                          spec: CakeSpec,
                          recipeName: String) -> [ProductionMaterial] {
        var materials: [ProductionMaterial] = []
        if result.batterGrams > 0 {
            materials.append(ProductionMaterial(name: "Masa de \(recipeName.lowercased())",
                                                quantity: result.batterGrams.rounded(),
                                                unit: .gram,
                                                isAutomatic: true,
                                                symbol: "birthday.cake"))
        }
        for ingredient in result.ingredients {
            materials.append(ProductionMaterial(name: ingredient.name,
                                                quantity: (ingredient.quantity * 10).rounded() / 10,
                                                unit: ingredient.unit,
                                                isAutomatic: true,
                                                inventoryItemID: ingredient.inventoryItemID,
                                                symbol: "bag"))
        }
        var fillingTotals: [String: Double] = [:]
        for tier in result.tiers {
            for filling in tier.fillings {
                fillingTotals[filling.name, default: 0] += filling.grams
            }
        }
        for (name, grams) in fillingTotals.sorted(by: { $0.key < $1.key }) {
            materials.append(ProductionMaterial(name: "Relleno de \(name.lowercased())",
                                                quantity: grams.rounded(),
                                                unit: .gram,
                                                isAutomatic: true,
                                                symbol: "drop"))
        }
        if result.coatingTotal > 0 {
            materials.append(ProductionMaterial(name: spec.coating.label,
                                                quantity: result.coatingTotal.rounded(),
                                                unit: .gram,
                                                isAutomatic: true,
                                                symbol: "paintbrush"))
        }
        if let first = spec.tiers.first {
            materials.append(ProductionMaterial(name: "Caja \(first.sizeLabel)",
                                                quantity: 1,
                                                unit: .unit,
                                                isAutomatic: true,
                                                symbol: "shippingbox"))
            materials.append(ProductionMaterial(name: "Base para pastel",
                                                quantity: 1,
                                                unit: .unit,
                                                isAutomatic: true,
                                                symbol: "circle"))
        }
        return materials
    }

    static func checklist(from result: CalculationResult, spec: CakeSpec) -> [ChecklistStep] {
        let perMold = result.tiers.first.map { "\(Fmt.number($0.batterPerMold.rounded())) g × \($0.moldCount)" } ?? ""
        return [
            ChecklistStep(title: "Masa preparada", detail: Fmt.grams(result.batterGrams.rounded())),
            ChecklistStep(title: "Moldeado", detail: perMold),
            ChecklistStep(title: "Relleno listo", detail: Fmt.grams(result.fillingGrams.rounded())),
            ChecklistStep(title: "Cobertura lista", detail: Fmt.grams(result.coatingTotal.rounded())),
            ChecklistStep(title: "Decoración terminada", detail: spec.coating.label)
        ]
    }
}
