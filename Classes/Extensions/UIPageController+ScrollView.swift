//
//  Created by Антон Лобанов on 17.05.2022.
//

import UIKit

public extension UIPageViewController {
	var scrollView: UIScrollView? {
		self.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView
	}
}
