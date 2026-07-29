import SwiftUI
import UIKit

/// カメラ撮影・フォトライブラリ選択の両方に使う `UIImagePickerController` ラッパー。
/// フォトライブラリ選択時は `imageURL` を通じてEXIFメタデータ抽出に使うファイルURLも返す。
struct ImagePickerView: UIViewControllerRepresentable {
    enum Source: Hashable, Identifiable {
        case camera
        case photoLibrary

        var id: Self { self }
    }

    let source: Source
    let onPick: (UIImage, URL?) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = source == .camera ? .camera : .photoLibrary
        if source == .camera {
            picker.cameraCaptureMode = .photo
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPick: (UIImage, URL?) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (UIImage, URL?) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.originalImage] as? UIImage) ?? UIImage()
            let url = info[.imageURL] as? URL
            onPick(image, url)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
