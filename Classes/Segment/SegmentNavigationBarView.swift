//
//  Created by Антон Лобанов on 22.02.2021.
//

import UIKit

protocol SegmentNavigationBarDelegate: AnyObject {
    func segmentNavigationBar(didSelect item: Int)
	func segmentNavigationBar(shouldSelect item: Int) -> Bool
}

open class SegmentNavigationBarView: UView {
	weak var delegate: SegmentNavigationBarDelegate?

	open func segmentHeight() -> CGFloat {
		return 0
	}

	open func segment(didScroll percentage: CGFloat) {}

	public func segment(didSelect index: Int) {
		self.delegate?.segmentNavigationBar(didSelect: index)
	}

	public func segment(shouldSelect index: Int) -> Bool {
		self.delegate?.segmentNavigationBar(shouldSelect: index) ?? true
	}

	public func selectSegment(at index: Int) {
		guard self.segment(shouldSelect: index) else { return }
		self.segment(didScroll: CGFloat(index))
		self.segment(didSelect: index)
	}
}
