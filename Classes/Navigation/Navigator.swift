//
//  Created by Антон Лобанов on 23.09.2021.
//

#if !os(macOS)
import UIKit

public enum NavigatorTransition {
	case setTab(Int)
	case push(IPresentable)
	case pop
	case popToRoot
	case present(IPresentable)
	case dismiss
	case dismissOnRoot
}

public protocol INavigator: AnyObject {
	func `switch`(
		to scene: SceneScreenType,
		animation: RootTransitionAnimation,
		completion: @escaping () -> Void
	)

	func perform(
		_ transition: NavigatorTransition,
		animated: Bool,
		completion: @escaping () -> Void
	)
}

public extension INavigator {
	func perform(
		_ transition: NavigatorTransition,
		animated: Bool = true,
		completion: @escaping () -> Void = { }
	) {
		self.perform(transition, animated: animated, completion: completion)
	}
}

public final class Navigator {
	private var topViewController: UIViewController {
		self.mainScene.viewController.topViewController
	}

	private var tabBarController: UITabBarController? {
		self.mainScene.viewController.children.first as? UITabBarController
	}

	private var mainScene: BaseApp.MainScene {
		BaseApp.shared.mainScene
	}

	public init() {}
}

extension Navigator: INavigator {
	public func `switch`(
		to scene: SceneScreenType,
		animation: RootTransitionAnimation,
		completion: @escaping () -> Void
	) {
		self.mainScene.switch(
			to: scene,
			animation: animation,
			beforeTransition: nil,
			completion: completion
		)
	}

	public func perform(
		_ transition: NavigatorTransition,
		animated: Bool,
		completion: @escaping () -> Void
	) {
		switch transition {
		case let .setTab(item):
			guard let tabBarController = self.tabBarController else {
				fatalError("Root controller must be UITabBarController")
			}
			tabBarController.selectedIndex = item
			completion()
		case let .push(presentable):
			self.topViewController.navigationController?.pushViewController(
				presentable.viewControllerToPresent,
				animated: animated,
				completion: completion
			)
		case .pop:
			self.topViewController.navigationController?.popViewController(
				animated: animated,
				completion: completion
			)
		case .popToRoot:
			self.topViewController.navigationController?.popToRootViewController(
				animated: animated,
				completion: completion
			)
		case let .present(presentable):
			self.topViewController.present(
				presentable.viewControllerToPresent,
				animated: animated,
				completion: completion
			)
		case .dismiss:
			self.topViewController.dismiss(
				animated: animated,
				completion: completion
			)
		case .dismissOnRoot:
			self.mainScene.viewController.dismiss(animated: animated, completion: completion)
		}
	}
}

private extension UIViewController {
	var topViewController: UIViewController {
		self.findTopViewController(self)
	}

	private func findTopViewController(_ controller: UIViewController) -> UIViewController {
		if let presented = controller.presentedViewController {
			return self.findTopViewController(presented)
		}

		if let tabController = controller as? UITabBarController, let selected = tabController.selectedViewController {
			return self.findTopViewController(selected)
		}

		if let navigationController = controller as? UINavigationController,
		   let lastViewController = navigationController.visibleViewController
		{
			return self.findTopViewController(lastViewController)
		}

		if let pageController = controller as? UIPageViewController,
		   let lastViewController = pageController.viewControllers?.first
		{
			return self.findTopViewController(lastViewController)
		}

		if let children = controller.children.first, children.view.isHidden == false {
			return self.findTopViewController(children)
		}

		return controller
	}
}

private extension UINavigationController {
	func pushViewController(_ viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
		self.pushViewController(viewController, animated: animated)

		guard animated, let coordinator = self.transitionCoordinator else {
			DispatchQueue.main.async { completion() }
			return
		}

		coordinator.animate(alongsideTransition: nil) { _ in completion() }
	}

	func popViewController(animated: Bool, completion: @escaping () -> Void) {
		self.popViewController(animated: animated)

		guard animated, let coordinator = self.transitionCoordinator else {
			DispatchQueue.main.async { completion() }
			return
		}

		coordinator.animate(alongsideTransition: nil) { _ in completion() }
	}

	func popToViewController(_ viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
		self.popToViewController(viewController, animated: animated)

		guard animated, let coordinator = self.transitionCoordinator else {
			DispatchQueue.main.async { completion() }
			return
		}

		coordinator.animate(alongsideTransition: nil) { _ in completion() }
	}

	func popToRootViewController(animated: Bool, completion: @escaping () -> Void) {
		self.popToRootViewController(animated: animated)

		guard animated, let coordinator = self.transitionCoordinator else {
			DispatchQueue.main.async { completion() }
			return
		}

		coordinator.animate(alongsideTransition: nil) { _ in completion() }
	}
}
#endif
