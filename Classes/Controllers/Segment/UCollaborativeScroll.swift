//
//  Created by Антон Лобанов on 20.02.2021.
//

import UIKit

public protocol UCollaborativeScroll: UIScrollView, UIGestureRecognizerDelegate {}

open class UCollaborativeScrollView: UIScrollView, UIGestureRecognizerDelegate, UCollaborativeScroll
{
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer.view is UIScrollView
    }
}

open class UCollaborativeCollectionView: UICollectionView, UIGestureRecognizerDelegate, UCollaborativeScroll
{
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer.view is UIScrollView
    }
}

open class UCollaborativeTableView: UITableView, UIGestureRecognizerDelegate, UCollaborativeScroll
{
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer.view is UIScrollView
    }
}
