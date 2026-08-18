import Foundation

nonisolated enum MeasureUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case gram
    case milliliter
    case unit

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gram: return "g"
        case .milliliter: return "ml"
        case .unit: return "unidades"
        }
    }

    var shortLabel: String {
        switch self {
        case .gram: return "g"
        case .milliliter: return "ml"
        case .unit: return "u"
        }
    }

    /// Whole units (eggs, boxes) can be rounded up to the next whole item.
    var isCountable: Bool { self == .unit }
}

nonisolated struct RecipeIngredient: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String = ""
    var quantity: Double = 0
    var unit: MeasureUnit = .gram
    var inventoryItemID: UUID?
}

/// A base recipe that the calculator scales mathematically by volume.
nonisolated struct Recipe: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "🎂"
    var photoURL: String = ""
    var shape: CakeShape = .round
    var panPrimarySize: Double = 6
    var panSecondarySize: Double = 10
    var referenceSpongeHeight: Double = 4
    var yieldGrams: Double = 900
    var ingredients: [RecipeIngredient] = []
    var procedure: String = ""
    var ovenTemperature: Int = 180
    var bakeMinutes: Int = 35
    var notes: String = ""

    /// Reference sponge volume in cubic inches used as the scaling baseline.
    var referenceVolume: Double {
        shape.area(primary: panPrimarySize, secondary: panSecondarySize) * referenceSpongeHeight
    }

    var referenceLabel: String {
        switch shape {
        case .rectangular:
            return "Molde \(Fmt.number(panPrimarySize, decimals: 1))×\(Fmt.number(panSecondarySize, decimals: 1))\" · alto \(Fmt.number(referenceSpongeHeight, decimals: 2))\""
        default:
            return "Molde \(Fmt.number(panPrimarySize, decimals: 1))\" · alto \(Fmt.number(referenceSpongeHeight, decimals: 2))\""
        }
    }
}

/// A filling or coating recipe registered by the pastry chef.
nonisolated struct FillingRecipe: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String = ""
    var kind: FillingKind = .buttercream
    var yieldGrams: Double = 500
    var ingredients: [RecipeIngredient] = []
    var notes: String = ""
}
