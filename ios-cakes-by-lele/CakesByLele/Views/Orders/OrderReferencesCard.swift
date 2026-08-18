import SwiftUI

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

/// Grid of attached photos plus a list of attached documents for one order.
struct OrderReferencesCard: View {
    let order: Order
    var onAdd: () -> Void
    var onOpen: (OrderAttachment) -> Void

    private let columns = [GridItem(.adaptive(minimum: 78), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Referencias (\(order.attachments.count))")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                Button(action: onAdd) {
                    Label("Añadir foto o PDF", systemImage: "plus.circle")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.accentDeep)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 34)
                        .background(Theme.blush, in: .capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Añadir foto o PDF")
            }

            if order.attachments.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(order.photoAttachments.enumerated()), id: \.element.id) { index, attachment in
                        photoTile(attachment, number: index + 1)
                    }
                    addTile
                }
                if !order.documentAttachments.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(order.documentAttachments) { document in
                            Button {
                                onOpen(document)
                            } label: {
                                documentRow(document)
                            }
                            .buttonStyle(.plain)
                            if document.id != order.documentAttachments.last?.id {
                                Divider().overlay(Theme.hairline)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .cardSurface()
    }

    private var emptyState: some View {
        Button(action: onAdd) {
            VStack(spacing: 8) {
                Image(systemName: "paperclip")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Theme.accentDeep)
                Text("Guarda aquí las fotos que envió la clienta y la cotización en PDF")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(Theme.canvas, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                    .foregroundStyle(Theme.accent.opacity(0.45))
            }
        }
        .buttonStyle(.plain)
    }

    private func photoTile(_ attachment: OrderAttachment, number: Int) -> some View {
        let isPinned = order.pinnedAttachmentID == attachment.id
        return Button {
            onOpen(attachment)
        } label: {
            AttachmentThumbnail(attachment: attachment, maxPixel: 320)
                .aspectRatio(1, contentMode: .fill)
                .overlay(alignment: .bottomTrailing) {
                    Text("\(number)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.accentDeep)
                        .frame(width: 20, height: 20)
                        .background(.white.opacity(0.92), in: .circle)
                        .padding(5)
                }
                .overlay(alignment: .topLeading) {
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Theme.accentDeep, in: .circle)
                            .padding(5)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isPinned ? Theme.accentDeep : Theme.hairline,
                                      lineWidth: isPinned ? 2 : 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Referencia \(number)\(isPinned ? ", fijada en producción" : "")")
    }

    private var addTile: some View {
        Button(action: onAdd) {
            ZStack {
                Theme.blush.opacity(0.6)
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.accentDeep)
            }
            .aspectRatio(1, contentMode: .fill)
            .clipShape(.rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                    .foregroundStyle(Theme.accent.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Añadir otra referencia")
    }

    private func documentRow(_ document: OrderAttachment) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.accentDeep)
                .frame(width: 34, height: 34)
                .background(Theme.blush, in: .rect(cornerRadius: 11))
            Text(document.displayName)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 8)
            Text(document.pagesLabel)
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.hairline)
        }
        .frame(minHeight: 48)
        .contentShape(.rect)
    }
}

/// Full-width gallery shown at the top of an order that already has photos.
struct ReferenceHeroGallery: View {
    let photos: [OrderAttachment]
    var onOpen: (OrderAttachment) -> Void

    @State private var index: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $index) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { position, photo in
                    Button {
                        onOpen(photo)
                    } label: {
                        AttachmentThumbnail(attachment: photo, maxPixel: 1200, cornerRadius: 0)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.plain)
                    .tag(position)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 8) {
                Text("Referencia \(min(index + 1, photos.count)) de \(photos.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.88), in: .capsule)
                HStack(spacing: 6) {
                    ForEach(photos.indices, id: \.self) { position in
                        Circle()
                            .fill(position == index ? Theme.accentDeep : Color.white.opacity(0.7))
                            .frame(width: position == index ? 7 : 6, height: position == index ? 7 : 6)
                    }
                }
            }
            .padding(.bottom, 14)
            .allowsHitTesting(false)
        }
        .frame(height: 260)
        .clipped()
    }
}
