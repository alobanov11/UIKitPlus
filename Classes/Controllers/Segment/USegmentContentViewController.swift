//
//  Created by Антон Лобанов on 21.02.2021.
//

import UIKit

public protocol USegmentContentDelegate: AnyObject
{
    func segmentContent(didScroll scrollView: UIScrollView)
}

open class USegmentContentViewController: ViewController {
	weak var delegate: USegmentContentDelegate?

	open func segmentShouldBeShowed() -> Bool {
		return true
	}

	open func segmentScrollView() -> UCollaborativeScroll {
		fatalError("Must be overriden")
	}
}
