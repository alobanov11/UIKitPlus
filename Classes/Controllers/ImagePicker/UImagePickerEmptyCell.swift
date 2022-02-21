//
//  Created by Антон Лобанов on 21.02.2022.
//

#if !os(macOS)

import UIKit
import Photos

struct UImagePickerEmptyItem: UItemable, UItemableBuilder, UItemableDelegate {
	var identifier: AnyHashable {
		self.text
	}

	let text: String

	func size(by original: CGSize, direction: UICollectionView.ScrollDirection) -> CGSize {
		original
	}

	func build(_ cell: UImagePickerEmptyCell) {
		cell.text = self.text
	}
}

final class UImagePickerEmptyCell: UCollectionCell {
	static var titleColor: UIColor = .white
	static var titleFont: UIFont = .systemFont(ofSize: 18, weight: .bold)

	@UState var text = ""

	override func buildView() {
		super.buildView()
		body {
			UWrapperView {
				UHStack {
					UText($text)
						.color(UImagePickerEmptyCell.titleColor)
						.font(v: UImagePickerEmptyCell.titleFont)
						.alignment(.center)
				}
				.alignment(.center)
			}
			.padding(32)
			.edgesToSuperview()
		}
	}
}

#endif
