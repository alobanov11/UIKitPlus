//
//  Created by Антон Лобанов on 18.05.2022.
//

import UIKit

extension UIBarButtonItem {
	public static func spacer(_ width: CGFloat = 20) -> UIBarButtonItem {
		let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
		spacer.width = width
		return spacer
	}
}
