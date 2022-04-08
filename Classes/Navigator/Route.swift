//
//  Created by Антон Лобанов on 08.04.2022.
//

#if !os(macOS)

import UIKit

public enum Route {
	case setRoot(Screen, RootTransitionAnimation)
	case setTab(Int)
	case push(Screen)
	case pop
	case popToRoot
	case present(Screen)
	case dismiss
	case dismissOnRoot
}

#endif
