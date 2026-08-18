import SwiftUI
import UIKit

/// Thin wrapper around the system camera so the chef can photograph a printed reference.
struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onFinish: { dismiss() })
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (Data) -> Void
        private let onFinish: () -> Void

        init(onCapture: @escaping (Data) -> Void, onFinish: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onFinish = onFinish
        }

        nonisolated func imagePickerController(_ picker: UIImagePickerController,
                                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            let data = image?.jpegData(compressionQuality: 0.9)
            Task { @MainActor in
                if let data { onCapture(data) }
                onFinish()
            }
        }

        nonisolated func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Task { @MainActor in onFinish() }
        }
    }
}
