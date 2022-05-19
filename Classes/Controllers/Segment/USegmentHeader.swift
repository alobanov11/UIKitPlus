//
//  Created by Антон Лобанов on 22.02.2021.
//

import UIKit

public protocol USegmentHeader: AnyObject {
	var headerView: UIView { get }
}

public extension USegmentHeader where Self: UIView {
	var headerView: UIView { self }
}

public extension USegmentHeader where Self: UIViewController {
	var UIView: UIView { self.view }
}
