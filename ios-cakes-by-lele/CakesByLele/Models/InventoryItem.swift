import Foundation

nonisolated enum InventoryCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case harinas
    case azucares
    case lacteos
    case chocolates
    case decoracion
    case empaque
    case otros

    var id: String { rawValue }

    var label: String {
        switch self {
        case .harinas: return "Harinas y secos"
        case .azucares: return "Azúcares"
        case .lacteos: return "Lácteos y huevos"
        case .chocolates: return "Chocolates"
        case .decoracion: return "Decoración"
        case .empaque: return "Empaque"
        case .otros: return "Otros"
        }
    }

    var systemImage: String {
        switch self {
        case .harinas: return "bag"
        case .azucares: return "cube"
        case .lacteos: return "drop"
        case .chocolates: return "square.stack.3d.up"
        case .decoracion: return "sparkles"
        case .empaque: return "shippingbox"
        case .otros: return "tray"
        }
    }
}

/// One pantry item with stock control and purchase cost.
nonisolated struct InventoryItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String = ""
    var category: InventoryCategory = .otros
    var unit: MeasureUnit = .gram
    var stock: Double = 0
    var minimumStock: Double = 0
    /// Quantity contained in the purchased package, e.g. 2000 g.
    var packageQuantity: Double = 1000
    /// Price paid for the whole package.
    var packagePrice: Double = 0
    var packageLabel: String = ""

    /// Cost of a single gram / millilitre / unit.
    var pricePerUnit: Double {
        packageQuantity > 0 ? packagePrice / packageQuantity : 0
    }

    var isLow: Bool { stock <= minimumStock }

    var stockLabel: String {
        unit == .unit
            ? "\(Fmt.number(stock)) unidades"
            : "\(Fmt.number(stock)) \(unit.shortLabel)"
    }

    var minimumLabel: String {
        unit == .unit
            ? "mínimo \(Fmt.number(minimumStock))"
            : "mínimo \(Fmt.number(minimumStock)) \(unit.shortLabel)"
    }
}
