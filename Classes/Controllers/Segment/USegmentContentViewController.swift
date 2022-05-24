//
//  Created by Антон Лобанов on 21.02.2021.
//

import UIKit

protocol USegmentContentDelegate: AnyObject {
    func segmentContent(didScroll scrollView: UIScrollView)
}

public enum USegmentContentState {
	case loading(withContent: Bool)
	case normal
	case error(Error)
}

open class USegmentContentViewController: ViewController {
	weak var delegate: USegmentContentDelegate?

	@UState public var isAvailable = true
	@UState public var contentState: USegmentContentState = .normal

	open func segmentDidRefresh() {}

	open func segmentScrollView() -> UCollaborativeScroll {
		fatalError("Must be overriden")
	}

	public func segmentDidScroll() {
		self.delegate?.segmentContent(didScroll: self.segmentScrollView())
	}
}
