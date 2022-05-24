//
//  Created by Антон Лобанов on 22.02.2021.
//

import UIKit

public protocol USegmentNavigationBarDelegate: AnyObject {
    func segmentNavigationBar(didSelect item: Int)
	func segmentNavigationBar(shouldSelect item: Int) -> Bool
}

open class USegmentNavigationBarView: UView {
	public internal(set) weak var delegate: USegmentNavigationBarDelegate?

	open func segmentHeight() -> CGFloat {
		return 0
	}

	open func segment(didScroll percentage: CGFloat) {}

	open func segment(didSelect index: Int) {}
}
