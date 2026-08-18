import Foundation
import ImageIO
import PDFKit
import UniformTypeIdentifiers
import UIKit

/// Disk storage for order references (photos and PDFs).
nonisolated enum AttachmentStore {
    /// Folder that keeps every attached photo and document.
    static var directory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("Referencias", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    static func exists(_ fileName: String) -> Bool {
        !fileName.isEmpty && FileManager.default.fileExists(atPath: url(for: fileName).path)
    }

    /// Writes the data to the attachments folder and returns the stored file name.
    @discardableResult
    static func write(_ data: Data, extension ext: String) throws -> String {
        let name = "\(UUID().uuidString).\(ext)"
        try data.write(to: url(for: name), options: .atomic)
        return name
    }

    static func data(for fileName: String) -> Data? {
        guard exists(fileName) else { return nil }
        return try? Data(contentsOf: url(for: fileName))
    }

    static func delete(fileName: String) {
        guard exists(fileName) else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    // MARK: - PDF helpers

    static func pdfPageCount(data: Data) -> Int {
        PDFDocument(data: data)?.pageCount ?? 1
    }

    static func pdfPageCount(fileName: String) -> Int {
        guard let raw = data(for: fileName) else { return 1 }
        return pdfPageCount(data: raw)
    }

    // MARK: - Thumbnails

    /// Downscaled JPEG preview for a stored attachment, safe to build off the main actor.
    static func thumbnailData(fileName: String, kind: AttachmentKind, maxPixel: CGFloat) -> Data? {
        guard let raw = data(for: fileName) else { return nil }
        return thumbnailData(from: raw, kind: kind, maxPixel: maxPixel)
    }

    static func thumbnailData(from raw: Data, kind: AttachmentKind, maxPixel: CGFloat) -> Data? {
        switch kind {
        case .photo:
            return downscaledJPEG(from: raw, maxPixel: maxPixel)
        case .pdf:
            guard let page = PDFDocument(data: raw)?.page(at: 0) else { return nil }
            let bounds = page.bounds(for: .mediaBox)
            guard bounds.width > 0, bounds.height > 0 else { return nil }
            let scale = maxPixel / max(bounds.width, bounds.height)
            let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            let image = page.thumbnail(of: size, for: .mediaBox)
            return image.jpegData(compressionQuality: 0.85)
        }
    }

    private static func downscaledJPEG(from raw: Data, maxPixel: CGFloat) -> Data? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(raw as CFData, options) else { return raw }
        let thumbOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions) else { return raw }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.85)
    }

    /// Re-encodes a picked photo so stored files stay reasonably small.
    static func normalizedPhotoData(_ raw: Data) -> Data {
        downscaledJPEG(from: raw, maxPixel: 2200) ?? raw
    }
}

/// Small in-memory cache so grids do not re-decode files while scrolling.
@MainActor
final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private var images: [String: UIImage] = [:]
    private var order: [String] = []
    private let limit = 80

    func image(for key: String) -> UIImage? { images[key] }

    func store(_ image: UIImage, for key: String) {
        if images[key] == nil { order.append(key) }
        images[key] = image
        while order.count > limit, let oldest = order.first {
            order.removeFirst()
            images.removeValue(forKey: oldest)
        }
    }

    func invalidate(fileName: String) {
        let keys = order.filter { $0.hasPrefix(fileName) }
        for key in keys {
            images.removeValue(forKey: key)
            order.removeAll { $0 == key }
        }
    }
}
