import PhotosUI
import SwiftUI
import UIKit

/// Item selected by the chef but not written to disk yet.
private struct PendingAttachment: Identifiable {
    let id = UUID()
    var kind: AttachmentKind
    var data: Data
    var displayName: String
    var preview: UIImage?
    var pageCount: Int = 1
}

/// Sheet used to attach client photos and signed quotes to a custom order.
struct AddAttachmentSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let orderID: UUID
    let clientName: String

    @State private var pending: [PendingAttachment] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var note: String = ""
    @State private var isCameraPresented = false
    @State private var isFileImporterPresented = false
    @State private var isImportingPhotos = false
    @State private var savedCount = 0
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var photoCount: Int { pending.filter { $0.kind == .photo }.count }
    private var documentCount: Int { pending.filter { $0.kind == .pdf }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                sourceCard
                if !pending.isEmpty {
                    selectionCard
                }
                noteCard
                actions
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.canvas)
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
        .photosPicker(isPresented: $isImportingPhotos,
                      selection: $pickerItems,
                      maxSelectionCount: 10,
                      matching: .images)
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importPickedPhotos(items) }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker { data in
                appendPhoto(data: data, name: "Foto \(photoCount + 1)")
            }
            .ignoresSafeArea()
        }
        .fileImporter(isPresented: $isFileImporterPresented,
                      allowedContentTypes: [.pdf],
                      allowsMultipleSelection: true) { result in
            handleFileImport(result)
        }
        .alert("No se pudo adjuntar", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Entendido", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Intenta de nuevo con otro archivo.")
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Añadir referencia")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("Guarda las fotos que envió la clienta y la cotización firmada")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sourceCard: some View {
        VStack(spacing: 0) {
            sourceRow(title: "Elegir de Fotos", symbol: "photo.on.rectangle") {
                isImportingPhotos = true
            }
            Divider().overlay(Theme.hairline)
            sourceRow(title: "Tomar foto", symbol: "camera") {
                if CameraPicker.isAvailable {
                    isCameraPresented = true
                } else {
                    errorMessage = "Este dispositivo no tiene cámara disponible."
                }
            }
            Divider().overlay(Theme.hairline)
            sourceRow(title: "Buscar archivo PDF", symbol: "doc.richtext") {
                isFileImporterPresented = true
            }
        }
        .cardSurface(padding: 4)
    }

    private func sourceRow(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accentDeep)
                    .frame(width: 34, height: 34)
                    .background(Theme.blush, in: .rect(cornerRadius: 11))
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.hairline)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 52)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var selectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectionSummary)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(pending) { item in
                        pendingTile(item)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
        .cardSurface()
    }

    private var selectionSummary: String {
        var parts: [String] = []
        if photoCount > 0 { parts.append("\(photoCount) \(photoCount == 1 ? "foto" : "fotos")") }
        if documentCount > 0 { parts.append("\(documentCount) PDF") }
        return parts.joined(separator: " · ") + " seleccionad\(photoCount + documentCount == 1 ? "o" : "os")"
    }

    private func pendingTile(_ item: PendingAttachment) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if let preview = item.preview {
                    Color(.secondarySystemBackground)
                        .frame(width: 92, height: 92)
                        .overlay {
                            Image(uiImage: preview)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 12))
                } else {
                    Theme.blush
                        .frame(width: 92, height: 92)
                        .overlay {
                            Image(systemName: item.kind.symbol)
                                .font(.system(size: 22, weight: .light))
                                .foregroundStyle(Theme.accentDeep)
                        }
                        .clipShape(.rect(cornerRadius: 12))
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        pending.removeAll { $0.id == item.id }
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 24, height: 24)
                        .background(.white, in: .circle)
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                }
                .buttonStyle(.plain)
                .padding(4)
                .accessibilityLabel("Quitar \(item.displayName)")
            }
            Text(item.displayName)
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 92)
        }
        .disabled(isSaving)
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nota de la referencia")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)
            TextField("Flores en tono durazno, base marfil", text: $note, axis: .vertical)
                .lineLimit(1...3)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Theme.canvas, in: .rect(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.hairline, lineWidth: 1)
                }
            if isSaving {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: Double(savedCount), total: Double(max(pending.count, 1)))
                        .tint(Theme.accentDeep)
                    Text("Guardando \(min(savedCount + 1, pending.count)) de \(pending.count)…")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                }
                .transition(.opacity)
            }
        }
        .cardSurface()
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                Task { await attach() }
            } label: {
                Label("Adjuntar al pedido", systemImage: "paperclip")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(pending.isEmpty || isSaving)
            .opacity(pending.isEmpty || isSaving ? 0.6 : 1)

            Button("Cancelar") { dismiss() }
                .buttonStyle(SoftButtonStyle())
                .disabled(isSaving)
        }
    }

    // MARK: - Importing

    private func importPickedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            do {
                guard let raw = try await item.loadTransferable(type: Data.self) else { continue }
                appendPhoto(data: raw, name: "Foto \(photoCount + 1)")
            } catch {
                errorMessage = "Una de las fotos no se pudo leer."
            }
        }
        pickerItems = []
    }

    private func appendPhoto(data raw: Data, name: String) {
        let normalized = AttachmentStore.normalizedPhotoData(raw)
        let preview = AttachmentStore.thumbnailData(from: normalized, kind: .photo, maxPixel: 300)
            .flatMap(UIImage.init(data:))
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            pending.append(PendingAttachment(kind: .photo,
                                             data: normalized,
                                             displayName: name,
                                             preview: preview))
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                let needsScope = url.startAccessingSecurityScopedResource()
                defer { if needsScope { url.stopAccessingSecurityScopedResource() } }
                guard let raw = try? Data(contentsOf: url) else {
                    errorMessage = "No se pudo leer \(url.lastPathComponent)."
                    continue
                }
                let preview = AttachmentStore.thumbnailData(from: raw, kind: .pdf, maxPixel: 300)
                    .flatMap(UIImage.init(data:))
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    pending.append(PendingAttachment(kind: .pdf,
                                                     data: raw,
                                                     displayName: url.lastPathComponent,
                                                     preview: preview,
                                                     pageCount: AttachmentStore.pdfPageCount(data: raw)))
                }
            }
        case .failure:
            errorMessage = "No se pudo abrir el archivo seleccionado."
        }
    }

    // MARK: - Saving

    private func attach() async {
        guard !pending.isEmpty else { return }
        isSaving = true
        savedCount = 0
        var saved: [OrderAttachment] = []
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        for item in pending {
            do {
                let ext = item.kind == .photo ? "jpg" : "pdf"
                let fileName = try AttachmentStore.write(item.data, extension: ext)
                saved.append(OrderAttachment(kind: item.kind,
                                            fileName: fileName,
                                            displayName: item.displayName,
                                            note: trimmedNote,
                                            sentBy: clientName,
                                            pageCount: item.kind == .pdf ? item.pageCount : 0))
                savedCount += 1
                try? await Task.sleep(for: .milliseconds(120))
            } catch {
                errorMessage = "No se pudo guardar \(item.displayName)."
            }
        }

        store.addAttachments(saved, to: orderID)
        isSaving = false
        if !saved.isEmpty { dismiss() }
    }
}
