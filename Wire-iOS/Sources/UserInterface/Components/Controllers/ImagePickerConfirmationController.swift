
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation

private extension UIImage {

    /// Fix the pngData method ignores orientation issue
    var flattened: UIImage {
        if imageOrientation == .up { return self }

        return UIGraphicsImageRenderer(size: size, format: imageRendererFormat).image { _ in draw(at: .zero) }
    }
}

/// Shows a confirmation dialog after picking an image in UIImagePickerController. If the user accepts
/// the image the imagePickedBlock is called.
final class ImagePickerConfirmationController: NSObject {
    var previewTitle: String? = nil
    @objc
    var imagePickedBlock: ((_ imageData: Data?) -> Void)?

    /// We need to store this reference to close the @c SketchViewController
    private var presentingPickerController: UIImagePickerController?

}

extension ImagePickerConfirmationController: UIImagePickerControllerDelegate {

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        presentingPickerController = picker

        guard let imageFromInfo = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }

        let image = imageFromInfo.flattened

        switch picker.sourceType {
        case .photoLibrary,
             .savedPhotosAlbum:

            let confirmImageViewController = ConfirmAssetViewController()
            confirmImageViewController.modalPresentationStyle = .fullScreen
            confirmImageViewController.image = image
            confirmImageViewController.previewTitle = previewTitle


            confirmImageViewController.onCancel = {
                picker.dismiss(animated: true)
            }

            confirmImageViewController.onConfirm = { [weak self] editedImage in
                if let editedImage = editedImage {
                    self?.imagePickedBlock?(editedImage.pngData())
                } else {
                    self?.imagePickedBlock?(image.pngData())
                }
            }

            picker.present(confirmImageViewController, animated: true)
            picker.setNeedsStatusBarAppearanceUpdate()

        case .camera:
            picker.dismiss(animated: true)
            imagePickedBlock?(image.pngData())
        @unknown default:
            picker.dismiss(animated: true)
            imagePickedBlock?(image.pngData())
        }
    }
}

extension ImagePickerConfirmationController: UINavigationControllerDelegate {
    
}
