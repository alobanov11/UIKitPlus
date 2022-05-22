#if !os(macOS)
import UIKit

public extension State where Value == CGFloat {
	static var zero: UState<CGFloat> {
		.init(wrappedValue: 0)
	}

	static func value(_ value: CGFloat) -> UState<CGFloat> {
		.init(wrappedValue: value)
	}
}

public extension CGFloat {
	static let width = UIScreen.main.bounds.width
	static let height = UIScreen.main.bounds.width
}

#endif
