import Foundation

nonisolated enum AttachmentKind: String, Codable, Hashable, Sendable {
    case photo
    case pdf

    var symbol: String {
        switch self {
        case .photo: return "photo.on.rectangle"
        case .pdf: return "doc.richtext"
        }
    }

    var label: String {
        switch self {
        case .photo: return "Foto"
        case .pdf: return "PDF"
        }
    }
}

/// A photo or PDF attached to a custom order. The binary lives in the
/// "Referencias" folder inside Documents; only its file name is persisted.
nonisolated struct OrderAttachment: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var kind: AttachmentKind = .photo
    /// File name inside the attachments folder, e.g. "A1B2-3C4D.jpg".
    var fileName: String = ""
    /// Name shown to the chef, e.g. "Cotización-Andrea.pdf".
    var displayName: String = ""
    var note: String = ""
    var sentBy: String = ""
    var createdAt: Date = Date()
    var pageCount: Int = 0

    var isPhoto: Bool { kind == .photo }

    var pagesLabel: String {
        pageCount <= 1 ? "1 página" : "\(pageCount) páginas"
    }

    var sourceLabel: String {
        let who = sentBy.trimmingCharacters(in: .whitespaces)
        let date = Fmt.shortDay(createdAt)
        return who.isEmpty ? date : "Enviada por \(who) · \(date)"
    }
}
