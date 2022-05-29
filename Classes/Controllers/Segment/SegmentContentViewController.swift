//
//  Created by Антон Лобанов on 21.02.2021.
//

import UIKit

protocol SegmentContentDelegate: AnyObject {
    func segmentContent(didScroll scrollView: UIScrollView)
}

public enum SegmentContentState {
	case loading(withContent: Bool)
	case normal
	case error(Error)
}

open class SegmentContentViewController: ViewController {
	weak var delegate: SegmentContentDelegate?

	@UState public var isAvailable = true
	@UState public var contentState: SegmentContentState = .normal

	open func segmentDidRefresh() {}

	open func segmentScrollView() -> UCollaborativeScroll {
		fatalError("Must be overriden")
	}

	public func segmentDidScroll() {
		self.delegate?.segmentContent(didScroll: self.segmentScrollView())
	}
}
