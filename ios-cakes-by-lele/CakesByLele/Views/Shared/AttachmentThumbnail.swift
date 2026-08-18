import SwiftUI
import UIKit

/// Square preview of a stored photo or PDF page, decoded off the main actor and cached.
struct AttachmentThumbnail: View {
    let attachment: OrderAttachment
    var maxPixel: CGFloat = 360
    var cornerRadius: CGFloat = 12

    @State private var image: UIImage?
    @State private var isMissing = false

    private var cacheKey: String { "\(attachment.fileName)-\(Int(maxPixel))" }

    var body: some View {
        ZStack {
            Theme.blush
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .allowsHitTesting(false)
            } else if isMissing {
                Image(systemName: attachment.kind.symbol)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Theme.accentDeep)
            } else {
                ProgressView()
                    .controlSize(.small)
                    .tint(Theme.accentDeep)
            }
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
        .task(id: cacheKey) { await load() }
    }

    private func load() async {
        if let cached = ThumbnailCache.shared.image(for: cacheKey) {
            image = cached
            return
        }
        let fileName = attachment.fileName
        let kind = attachment.kind
        let pixels = maxPixel
        let data = await Task.detached(priority: .userInitiated) {
            AttachmentStore.thumbnailData(fileName: fileName, kind: kind, maxPixel: pixels)
        }.value
        guard let data, let decoded = UIImage(data: data) else {
            isMissing = true
            return
        }
        ThumbnailCache.shared.store(decoded, for: cacheKey)
        withAnimation(.easeOut(duration: 0.2)) { image = decoded }
    }
}

/// Full resolution image loader used by the reference viewer.
struct AttachmentFullImage: View {
    let attachment: OrderAttachment
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView().tint(.white)
            }
        }
        .task(id: attachment.fileName) { await load() }
    }

    private func load() async {
        let fileName = attachment.fileName
        let kind = attachment.kind
        let data = await Task.detached(priority: .userInitiated) {
            AttachmentStore.thumbnailData(fileName: fileName, kind: kind, maxPixel: 2400)
        }.value
        guard let data, let decoded = UIImage(data: data) else { return }
        image = decoded
    }
}
