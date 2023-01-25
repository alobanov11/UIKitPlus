//
//  Created by Антон Лобанов on 25.01.2023.
//

import UIKit

open class PassthroughView<T: UIView>: UWrapperView<T> {
	open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		hitTestHandler?(self.innerView.hitTest(convert(point, to: self.innerView), with: event)) != nil
	}

	private var hitTestHandler: ((UIView?) -> UIView?)?

	public func onHitTest(_ handler: @escaping (UIView?) -> UIView?) -> Self {
		self.hitTestHandler = handler
		return self
	}
}
