import Foundation

nonisolated enum LengthUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case inches
    case centimeters

    var id: String { rawValue }
    var label: String { self == .inches ? "pulgadas" : "cm" }
    var suffix: String { self == .inches ? "\"" : " cm" }

    func fromInches(_ inches: Double) -> Double { self == .inches ? inches : inches * 2.54 }
    func toInches(_ value: Double) -> Double { self == .inches ? value : value / 2.54 }
}

nonisolated enum CakeShape: String, Codable, CaseIterable, Identifiable, Sendable {
    case round
    case square
    case rectangular

    var id: String { rawValue }

    var label: String {
        switch self {
        case .round: return "Redondo"
        case .square: return "Cuadrado"
        case .rectangular: return "Rectangular"
        }
    }

    var systemImage: String {
        switch self {
        case .round: return "circle"
        case .square: return "square"
        case .rectangular: return "rectangle"
        }
    }

    /// Base area in square inches for the given primary and secondary measurements.
    func area(primary: Double, secondary: Double) -> Double {
        switch self {
        case .round: return .pi * pow(primary / 2, 2)
        case .square: return primary * primary
        case .rectangular: return primary * secondary
        }
    }

    /// Perimeter in inches, used for coating the sides.
    func perimeter(primary: Double, secondary: Double) -> Double {
        switch self {
        case .round: return .pi * primary
        case .square: return primary * 4
        case .rectangular: return (primary + secondary) * 2
        }
    }

    var primaryLabel: String {
        switch self {
        case .round: return "Diámetro"
        case .square: return "Lado"
        case .rectangular: return "Ancho"
        }
    }
}

nonisolated enum FillingKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case ganache
    case dulceDeLeche
    case buttercream
    case crema
    case chocolate
    case fresa
    case personalizado

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ganache: return "Ganache"
        case .dulceDeLeche: return "Dulce de leche"
        case .buttercream: return "Buttercream"
        case .crema: return "Crema"
        case .chocolate: return "Chocolate"
        case .fresa: return "Fresa"
        case .personalizado: return "Personalizado"
        }
    }

    /// Approximate density in grams per cubic inch.
    var gramsPerCubicInch: Double {
        switch self {
        case .ganache: return 18.0
        case .dulceDeLeche: return 21.0
        case .buttercream: return 14.8
        case .crema: return 11.5
        case .chocolate: return 19.5
        case .fresa: return 13.0
        case .personalizado: return 15.0
        }
    }
}

nonisolated enum CoatingKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case buttercream
    case ganache
    case crema
    case fondant
    case otro

    var id: String { rawValue }

    var label: String {
        switch self {
        case .buttercream: return "Buttercream"
        case .ganache: return "Ganache"
        case .crema: return "Crema"
        case .fondant: return "Fondant"
        case .otro: return "Otro"
        }
    }

    /// Grams needed per square centimeter of surface.
    var gramsPerSquareCentimeter: Double {
        switch self {
        case .buttercream: return 0.55
        case .ganache: return 0.65
        case .crema: return 0.45
        case .fondant: return 0.75
        case .otro: return 0.55
        }
    }
}

nonisolated enum ServingSize: String, Codable, CaseIterable, Identifiable, Sendable {
    case small
    case normal
    case large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return "Pequeña"
        case .normal: return "Normal"
        case .large: return "Grande"
        }
    }

    /// Footprint of one serving in square inches.
    var footprintSquareInches: Double {
        switch self {
        case .small: return 2.0
        case .normal: return 4.0
        case .large: return 6.0
        }
    }
}

nonisolated struct SpongeLayer: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var height: Double = 2.0
}

nonisolated struct FillingLayer: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var kind: FillingKind = .buttercream
    var customName: String = ""
    var thickness: Double = 0.5

    var displayName: String {
        kind == .personalizado && !customName.isEmpty ? customName : kind.label
    }
}

/// One complete cake placed on top of another one — a tier ("piso").
nonisolated struct CakeTier: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var shape: CakeShape = .round
    var primarySize: Double = 8      // diameter / side / width, in inches
    var secondarySize: Double = 12   // length for rectangular tiers, in inches
    var layers: [SpongeLayer] = [SpongeLayer(), SpongeLayer(), SpongeLayer()]
    var fillings: [FillingLayer] = [FillingLayer(), FillingLayer()]
    var recipeID: UUID?

    var spongeHeight: Double { layers.reduce(0) { $0 + $1.height } }
    var fillingHeight: Double { fillings.reduce(0) { $0 + $1.thickness } }
    var totalHeight: Double { spongeHeight + fillingHeight }
    var area: Double { shape.area(primary: primarySize, secondary: secondarySize) }
    var perimeter: Double { shape.perimeter(primary: primarySize, secondary: secondarySize) }
    var spongeVolume: Double { area * spongeHeight }

    var sizeLabel: String {
        switch shape {
        case .rectangular:
            return "\(Fmt.number(primarySize, decimals: 1))×\(Fmt.number(secondarySize, decimals: 1))\""
        default:
            return "\(Fmt.number(primarySize, decimals: 1))\""
        }
    }

    /// Keeps the number of fillings consistent with the number of sponge layers.
    mutating func normalizeFillings() {
        let target = max(layers.count - 1, 0)
        while fillings.count > target { fillings.removeLast() }
        while fillings.count < target {
            fillings.append(FillingLayer(kind: fillings.last?.kind ?? .buttercream,
                                         thickness: fillings.last?.thickness ?? 0.5))
        }
    }
}

/// Full configuration of a cake: one or more tiers plus coating and serving options.
nonisolated struct CakeSpec: Codable, Hashable, Sendable {
    var tiers: [CakeTier] = [CakeTier()]
    var coating: CoatingKind = .buttercream
    var wastePercent: Double = 0.10
    var servingSize: ServingSize = .normal
    var roundEggs: Bool = true
    var unit: LengthUnit = .inches

    var totalHeight: Double { tiers.reduce(0) { $0 + $1.totalHeight } }
    var tierCount: Int { tiers.count }

    var summaryLabel: String {
        guard let first = tiers.first else { return "Sin pisos" }
        if tiers.count == 1 { return "\(first.shape.label) \(first.sizeLabel)" }
        return tiers.map(\.sizeLabel).joined(separator: " · ")
    }

    static func tierName(index: Int, total: Int) -> String {
        if total == 1 { return "Piso único" }
        if index == 0 { return "Piso superior" }
        if index == total - 1 { return "Piso inferior" }
        return "Piso medio \(index)"
    }
}
