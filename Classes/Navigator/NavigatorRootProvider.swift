//
//  Created by Антон Лобанов on 08.04.2022.
//

#if !os(macOS)

import UIKit

public protocol NavigatorRootProvider {
	var topViewController: UIViewController? { get }

	var rootViewController: UIViewController? { get }

	func `switch`(
		to: UIViewController,
		animation: RootTransitionAnimation,
		completion: (() -> Void)?
	)
}

public final class BaseNavigatorRootProvider: NavigatorRootProvider {
	public var topViewController: UIViewController? {
		BaseApp.mainScene.topViewController
	}

	public var rootViewController: UIViewController? {
		BaseApp.mainScene.current
	}

	public init() {}

	public func `switch`(
		to: UIViewController,
		animation: RootTransitionAnimation,
		completion: (() -> Void)?
	) {
		BaseApp.mainScene.switch(
			to: to,
			as: .main,
			animation: animation,
			beforeTransition: nil,
			completion: completion
		)
	}
}

#endif
