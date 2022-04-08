//
//  Created by Антон Лобанов on 08.04.2022.
//

#if !os(macOS)

import UIKit

public protocol Screen {
	func build() -> UIViewController?
}

#endif
