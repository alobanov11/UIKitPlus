//
//  Created by Антон Лобанов on 22.02.2021.
//

import UIKit

protocol USegmentNavigationBarDelegate: AnyObject {
    func segmentNavigationBar(didSelect item: Int)
}

open class USegmentNavigationBarView: UView {
	weak var delegate: USegmentNavigationBarDelegate?

	open func segmentHeight() -> CGFloat {
		return 0
	}

	open func segment(didScroll percentage: CGFloat) {}

	public func segment(didSelect index: Int) {
		self.delegate?.segmentNavigationBar(didSelect: index)
	}
}
