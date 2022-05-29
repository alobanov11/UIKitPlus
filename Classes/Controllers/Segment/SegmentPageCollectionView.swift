//
//  Created by Антон Лобанов on 13.03.2021.
//

import UIKit

protocol SegmentPageCollectionAdapter: UIViewController {
    func segmentPageCollection(isAvailable index: Int) -> Bool
    func segmentPageCollectionViewControllers() -> [UIViewController]
    func segmentPageCollectionWillBeginDragging()
    func segmentPageCollectionDidEndDragging()
    func segmentPageCollection(didScroll point: CGPoint)
}

final class SegmentPageCollectionView: UIView {
	var currentIndex: Int {
		let viewControllers = self.adapter.segmentPageCollectionViewControllers()
		guard let viewController = pageViewController.viewControllers?.first,
			  let index = viewControllers.firstIndex(of: viewController)
		else {
			return 0
		}
		return index
	}

	var horziontalScrollView: UIScrollView? {
		self.pageViewController.scrollView
	}

    private(set) var selectedIndex = 0

    private lazy var pageViewController: UIPageViewController = {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        controller.delegate = self
        controller.view.translatesAutoresizingMaskIntoConstraints = false
		controller.scrollView?.delegate = self
		if #available(iOS 11.0, *) {
			controller.scrollView?.contentInsetAdjustmentBehavior = .never
		}
        return controller
    }()

    private weak var adapter: SegmentPageCollectionAdapter!

    private var shouldListenScroll = true
	private var isHorizontallScrollEnabled = false

    init(adapter: SegmentPageCollectionAdapter) {
        self.adapter = adapter

        super.init(frame: .zero)

        adapter.addChild(self.pageViewController)
        self.addSubview(self.pageViewController.view)

        NSLayoutConstraint.activate([
            self.pageViewController.view.topAnchor.constraint(equalTo: self.topAnchor),
            self.pageViewController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.pageViewController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.pageViewController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.pageViewController.view.widthAnchor.constraint(equalTo: self.widthAnchor),
            self.pageViewController.view.heightAnchor.constraint(equalTo: self.heightAnchor),
        ])

        self.pageViewController.didMove(toParent: adapter)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func scrollToItem(
        at index: Int,
        animated: Bool = true
    ) {
        let viewControllers = self.adapter.segmentPageCollectionViewControllers()
        guard viewControllers.indices.contains(where: { $0 == index }) else { return }
        self.shouldListenScroll = false
        self.pageViewController.setViewControllers(
            [viewControllers[index]],
            direction: index > self.selectedIndex
                || (index == 0 && self.selectedIndex == 0)
                ? .forward
                : .reverse,
            animated: animated,
            completion: { _ in
                self.shouldListenScroll = true
                self.selectedIndex = index
            }
        )
    }

    func invalidate() {
		guard self.isHorizontallScrollEnabled else { return }
        self.pageViewController.dataSource = nil
        self.pageViewController.dataSource = self
    }

	func enableHorizontalScroll() {
		self.pageViewController.dataSource = self
	}

	func hasViewControllerBefore() -> Bool {
		guard let currentViewController = self.pageViewController.viewControllers?.first,
			  self.pageViewController(self.pageViewController, viewControllerBefore: currentViewController) == nil
		else {
			return true
		}
		return false
	}
}

extension SegmentPageCollectionView: UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        let viewControllers = self.adapter.segmentPageCollectionViewControllers()

        guard let index = viewControllers.firstIndex(where: { $0 == viewController }),
              viewControllers.indices.contains(where: { $0 == index - 1 }),
              self.adapter.segmentPageCollection(isAvailable: (index - 1))
        else {
            return nil
        }

        return viewControllers[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        let viewControllers = self.adapter.segmentPageCollectionViewControllers()

        guard let index = viewControllers.firstIndex(where: { $0 == viewController }),
              viewControllers.indices.contains(where: { $0 == index + 1 }),
              self.adapter.segmentPageCollection(isAvailable: (index + 1))
        else {
            return nil
        }

        return viewControllers[index + 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        let viewControllers = self.adapter.segmentPageCollectionViewControllers()
        guard let viewController = pageViewController.viewControllers?.first,
              let index = viewControllers.firstIndex(of: viewController)
        else {
            return
        }
        self.shouldListenScroll = true
        self.selectedIndex = index
    }
}

extension SegmentPageCollectionView: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = self.frame.width
        let startX = CGFloat(self.selectedIndex) * width
        let offsetX = scrollView.contentOffset.x + startX
        guard self.shouldListenScroll else { return }
        self.adapter.segmentPageCollection(didScroll: .init(x: offsetX, y: 0))
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.adapter.segmentPageCollectionWillBeginDragging()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.adapter.segmentPageCollectionDidEndDragging()
    }
}
