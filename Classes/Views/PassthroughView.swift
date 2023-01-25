//
//  Created by Антон Лобанов on 25.01.2023.
//

import UIKit

open class PassthroughView: UView {
	open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let view = super.hitTest(point, with: event)
		return view == self ? nil : view
	}
}
