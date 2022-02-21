//
//  Created by Антон Лобанов on 21.02.2022.
//

#if !os(macOS)

import UIKit
import Photos

struct UImagePickerItem: UItemable, UItemableBuilder, UItemableDelegate {
	var identifier: AnyHashable {
		[self.asset.localIdentifier, self.selected] as [AnyHashable]
	}

	let asset: PHAsset
	var selected: Bool
	let onSelect: () -> Void

	func size(by original: CGSize, direction: UICollectionView.ScrollDirection) -> CGSize {
		.init(width: original.width / 3, height: original.width / 3)
	}

	func build(_ cell: UImagePickerCell) {
		cell.asset = self.asset
		cell.choosed = self.selected
	}

	func didSelect() {
		self.onSelect()
	}
}

final class UImagePickerCell: UCollectionCell {
	static var selectedBackgroundColor: UIColor = .black.withAlphaComponent(0.4)
	static var pinBackgroundColor: UIColor = .gray

	@UState var asset: PHAsset?
	@UState var choosed = false

	private static let imageManager = PHImageManager.default()

	private var imageRequestId: PHImageRequestID?
	private var imageView: UImage?

	override func prepareForReuse() {
		super.prepareForReuse()
		self.imageRequestId.map {
			UImagePickerCell.imageManager.cancelImageRequest($0)
		}
		self.imageRequestId = nil
		self.imageView?.image = nil
	}

	override func buildView() {
		super.buildView()
		body {
			UWrapperView {
				UView {
					UImage(nil)
						.mode(.scaleAspectFill)
						.bind($asset) { [weak self] _, asset in
							guard let asset = asset else { return }

							let options = PHImageRequestOptions()
							options.deliveryMode = .highQualityFormat
							options.resizeMode = .fast
							options.isSynchronous = false
							options.isNetworkAccessAllowed = true

							let size = (UIScreen.main.bounds.width / 2)

							self?.imageRequestId = UImagePickerCell.imageManager.requestImage(
								for: asset,
								targetSize: .init(width: size, height: size),
								contentMode: .default,
								options: options
							) { result, _ in
								self?.imageRequestId = nil
								self?.imageView?.image = result
							}
						}
						.itself(&imageView)
						.edgesToSuperview()
					UView()
						.background(UImagePickerCell.selectedBackgroundColor)
						.hidden($choosed.map { $0 == false })
						.edgesToSuperview()
					UView()
						.border(1, .white)
						.background(UImagePickerCell.pinBackgroundColor)
						.size(20)
						.circle()
						.topToSuperview(6)
						.trailingToSuperview(-6)
						.hidden($choosed.map { $0 == false })
				}
			}
			.padding(3)
			.edgesToSuperview()
		}
	}
}

#endif
