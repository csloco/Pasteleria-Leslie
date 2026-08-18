import PDFKit
import SwiftUI

/// Full screen reference viewer: zoomable photos, PDF pages, note and quick actions.
struct AttachmentViewerView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let orderID: UUID
    @State private var currentID: UUID
    @State private var zoom: CGFloat = 1
    @State private var showDeleteConfirmation = false

    init(orderID: UUID, startID: UUID) {
        self.orderID = orderID
        _currentID = State(initialValue: startID)
    }

    private var order: Order? { store.data.orders.first { $0.id == orderID } }
    private var attachments: [OrderAttachment] { order?.attachments ?? [] }
    private var currentIndex: Int { attachments.firstIndex { $0.id == currentID } ?? 0 }
    private var current: OrderAttachment? { attachments[safe: currentIndex] }

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()
            if let current {
                VStack(spacing: 0) {
                    topBar(current)
                    stage(current)
                    caption(current)
                    filmstrip
                    actions(current)
                }
            } else {
                VStack(spacing: 12) {
                    Text("Esta referencia ya no está disponible")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Button("Cerrar") { dismiss() }
                        .buttonStyle(.bordered)
                        .tint(.white)
                }
            }
        }
        .confirmationDialog("¿Eliminar esta referencia?",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible) {
            Button("Eliminar referencia", role: .destructive) { deleteCurrent() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("El archivo se borrará del pedido y del dispositivo.")
        }
    }

    // MARK: - Sections

    private func topBar(_ attachment: OrderAttachment) -> some View {
        ZStack {
            Text("Referencia \(currentIndex + 1) de \(attachments.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.16), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar")
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func stage(_ attachment: OrderAttachment) -> some View {
        if attachment.isPhoto {
            AttachmentFullImage(attachment: attachment)
                .scaleEffect(zoom)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in zoom = min(max(value.magnification, 1), 4) }
                        .onEnded { _ in withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { zoom = 1 } }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { zoom = zoom > 1 ? 1 : 2.2 }
                }
        } else {
            PDFPreview(fileName: attachment.fileName)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func caption(_ attachment: OrderAttachment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(attachment.note.isEmpty ? attachment.displayName : attachment.note)
                .font(.headline)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(attachment.isPhoto
                 ? attachment.sourceLabel
                 : "\(attachment.displayName) · \(attachment.pagesLabel)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var filmstrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(Array(attachments.enumerated()), id: \.element.id) { index, attachment in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            currentID = attachment.id
                            zoom = 1
                        }
                    } label: {
                        VStack(spacing: 4) {
                            AttachmentThumbnail(attachment: attachment, maxPixel: 220, cornerRadius: 10)
                                .frame(width: 62, height: 62)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(attachment.id == currentID ? Theme.accent : Color.clear,
                                                      lineWidth: 2.5)
                                }
                            Text(attachment.isPhoto ? "\(index + 1)" : "PDF p. 1")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(attachment.id == currentID ? Theme.accent : .white.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 20, for: .scrollContent)
    }

    private func actions(_ attachment: OrderAttachment) -> some View {
        HStack(spacing: 10) {
            ShareLink(item: AttachmentStore.url(for: attachment.fileName)) {
                actionLabel("Compartir", symbol: "square.and.arrow.up", tint: .white)
            }
            .buttonStyle(.plain)

            Button {
                store.pinAttachment(id: attachment.id, in: orderID)
            } label: {
                actionLabel(order?.pinnedAttachmentID == attachment.id ? "Fijada" : "Fijar en producción",
                            symbol: order?.pinnedAttachmentID == attachment.id ? "pin.fill" : "pin",
                            tint: order?.pinnedAttachmentID == attachment.id ? Theme.accent : .white)
            }
            .buttonStyle(.plain)

            Button {
                showDeleteConfirmation = true
            } label: {
                actionLabel("Eliminar", symbol: "trash", tint: Color(red: 0.92, green: 0.55, blue: 0.55))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func actionLabel(_ title: String, symbol: String, tint: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, minHeight: 62)
        .background(.white.opacity(0.1), in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        }
    }

    private func deleteCurrent() {
        guard let current else { return }
        let nextID = attachments[safe: currentIndex + 1]?.id ?? attachments[safe: currentIndex - 1]?.id
        store.deleteAttachment(id: current.id, from: orderID)
        if let nextID {
            currentID = nextID
        } else {
            dismiss()
        }
    }
}

/// Native PDF reader for attached quotes and sketches.
struct PDFPreview: UIViewRepresentable {
    let fileName: String

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.backgroundColor = .clear
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        let url = AttachmentStore.url(for: fileName)
        if view.document?.documentURL != url {
            view.document = PDFDocument(url: url)
        }
    }
}
