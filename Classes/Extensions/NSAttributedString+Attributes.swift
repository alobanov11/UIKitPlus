//
//  Created by Антон Лобанов on 24.11.2022.
//

import Foundation

extension NSAttributedString {
	public var attributes: [NSAttributedString.Key: Any] {
		guard self.length > 0 else { return [:] }
		return self.attributes(at: 0, effectiveRange: nil)
	}
}
