//
//  Created by Антон Лобанов on 23.09.2021.
//

#if !os(macOS)
import UIKit

public protocol INavigationMap: AnyObject {
	func splash() -> IPresentable
	func onboarding() -> IPresentable
	func login() -> IPresentable
	func main() -> IPresentable
}

public extension INavigationMap {
	func splash() -> IPresentable { UIViewController() }
	func onboarding() -> IPresentable { UIViewController() }
	func login() -> IPresentable { UIViewController() }
	func main() -> IPresentable { UIViewController() }
}
#endif
