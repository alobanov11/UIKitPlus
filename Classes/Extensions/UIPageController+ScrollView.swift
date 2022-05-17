//
//  Created by Антон Лобанов on 17.05.2022.
//

import UIKit

public extension UIPageViewController {
	var scrollView: UIScrollView? {
		for subview in self.view.subviews {
			if let scrollView = subview as? UIScrollView {
				return scrollView
			}
		}
		return nil
	}
}
