//
//  Created by Антон Лобанов on 21.02.2022.
//

#if !os(macOS)

import UIKit
import Photos

struct UImageAlbumItem: UItemable, UItemableBuilder, UItemableDelegate {
	var identifier: AnyHashable {
		[self.album.localIdentifier] as [AnyHashable]
	}

	let album: PHAssetCollection
	let onSelect: () -> Void

	func build(_ cell: UImageAlbumCell) {
		cell.title = self.album.localizedTitle ?? "*"
		cell.asset = {
			let assets = PHAsset.fetchAssets(in: self.album, options: nil)
			return assets.firstObject
		}()
	}

	func didSelect() {
		self.onSelect()
	}
}

final class UImageAlbumCell: UCollectionCell {
	static var titleColor: UIColor = .white
	static var titleFont: UIFont = .systemFont(ofSize: 18, weight: .bold)

	@UState var title = ""
	@UState var asset: PHAsset?

	private static let imageManager = PHImageManager.default()

	private var imageRequestId: PHImageRequestID?
	private var imageView: UImage?

	override func prepareForReuse() {
		super.prepareForReuse()
		self.imageRequestId.map {
			UImageAlbumCell.imageManager.cancelImageRequest($0)
		}
		self.imageRequestId = nil
		self.imageView?.image = nil
	}

	override func buildView() {
		super.buildView()
		body {
			UWrapperView {
				UHStack {
					UImage(nil)
						.mode(.scaleAspectFill)
						.bind($asset) { [weak self] _, asset in
							guard let asset = asset else { return }

							let options = PHImageRequestOptions()
							options.deliveryMode = .highQualityFormat
							options.resizeMode = .fast
							options.isSynchronous = false
							options.isNetworkAccessAllowed = true

							let size = (UIScreen.main.bounds.width / 3)

							self?.imageRequestId = UImageAlbumCell.imageManager.requestImage(
								for: asset,
								targetSize: .init(width: size, height: size),
								contentMode: .aspectFill,
								options: options
							) { result, _ in
								self?.imageRequestId = nil
								self?.imageView?.image = result
							}
						}
						.size(60)
						.itself(&imageView)
					UText($title)
						.color(UImageAlbumCell.titleColor)
						.font(v: UImageAlbumCell.titleFont)
				}
				.spacing(16)
				.alignment(.center)
			}
			.padding(8)
			.edgesToSuperview()
		}
	}
}

#endif
