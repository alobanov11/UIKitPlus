//
//  Created by Антон Лобанов on 20.02.2021.
//

import UIKit

public protocol UCollaborativeScroll: UIScrollView, UIGestureRecognizerDelegate {}

open class UCollaborativeScrollView: UScrollView, UIGestureRecognizerDelegate, UCollaborativeScroll
{
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer.view is UCollaborativeScroll
    }
}

open class UCollaborativeCollectionView: UCollectionView, UIGestureRecognizerDelegate, UCollaborativeScroll
{
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer.view is UCollaborativeScroll
    }
}

open class UCollaborativeTableView: UTableView, UIGestureRecognizerDelegate, UCollaborativeScroll
{
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer.view is UCollaborativeScroll
    }
}
