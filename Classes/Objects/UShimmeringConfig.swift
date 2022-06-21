//
//  Created by Антон Лобанов on 22.06.2022.
//

import UIKit

public struct UShimmeringConfig {
	public let colors: [UIColor]
	public let duration: TimeInterval

	init(colors: [UIColor], duration: TimeInterval) {
		self.colors = colors
		self.duration = duration
	}
}

extension UShimmeringConfig {
	public static let `default` = UShimmeringConfig(
		colors: [
			UIColor(white: 0.85, alpha: 1.0),
			UIColor(white: 0.95, alpha: 1.0),
			UIColor(white: 0.85, alpha: 1.0),
		],
		duration: 0.9
	)
}
