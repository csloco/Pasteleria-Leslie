import Foundation

/// Shared number, currency and date formatting for the app.
nonisolated enum Fmt {
    static let locale = Locale(identifier: "es_GT")

    static func number(_ value: Double, decimals: Int = 0) -> String {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = decimals
        return f.string(from: NSNumber(value: value)) ?? "0"
    }

    /// Formats a currency amount in quetzales, e.g. Q1,850.00
    static func money(_ value: Double, decimals: Int = 2) -> String {
        "Q" + number(value, decimals: decimals)
    }

    static func grams(_ value: Double) -> String {
        value >= 1000 ? "\(number(value / 1000, decimals: 2)) kg" : "\(number(value)) g"
    }

    /// Formats a length, trimming trailing zeros: 2.25" or 6 cm
    static func length(_ inches: Double, unit: LengthUnit) -> String {
        let value = unit == .inches ? inches : inches * 2.54
        return number(value, decimals: 2) + unit.suffix
    }

    static func percent(_ fraction: Double) -> String {
        number(fraction * 100, decimals: 0) + "%"
    }

    static func dayTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "EEEE d 'de' MMMM"
        return f.string(from: date).capitalizedFirst
    }

    static func shortDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "EEE d MMM"
        return f.string(from: date).capitalizedFirst
    }

    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    static func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date).capitalizedFirst
    }

    static func greeting(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<12: return "Buenos días"
        case 12..<19: return "Buenas tardes"
        default: return "Buenas noches"
        }
    }
}

nonisolated extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}

nonisolated extension Calendar {
    static let app: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Fmt.locale
        c.firstWeekday = 2
        return c
    }()
}
