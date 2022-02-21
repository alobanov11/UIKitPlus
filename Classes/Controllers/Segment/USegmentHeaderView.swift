//
//  Created by Антон Лобанов on 22.02.2021.
//

import UIKit

protocol USegmentHeaderDelegate: AnyObject {
	func segmentHeaderReload()
}

open class USegmentHeaderView: UView {
	weak var delegate: USegmentHeaderDelegate?

	open override func layoutSubviews() {
		super.layoutSubviews()
		self.delegate?.segmentHeaderReload()
	}
}
