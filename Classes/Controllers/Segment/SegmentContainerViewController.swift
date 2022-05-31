//
//  Created by Антон Лобанов on 20.02.2021.
//

import UIKit

open class SegmentContainerViewController: ViewController {
	public var currentViewController: SegmentContentViewController {
		self.viewControllers[self.pageCollectionView.currentIndex]
	}

	@UState public var contentState: SegmentContentState = .normal

    public private(set) var headerView: SegmentHeaderView?
	public private(set) var navigationBar: SegmentNavigationBarView
    public private(set) var viewControllers: [SegmentContentViewController] = []

    // MARK: - UI

    private lazy var verticalCollectionView = SegmentVerticalCollectionView(adapter: self)
    private lazy var pageCollectionView = SegmentPageCollectionView(adapter: self)

    // MARK: - Variables

    private var visibleCollaborativeScrollView: UIScrollView {
        return self.viewControllers[self.pageCollectionView.selectedIndex].segmentScrollView()
    }

    private var lastCollaborativeScrollView: UIScrollView?
	private var backGesture: UIPanGestureRecognizer?

	private let initialIndex: Int

    // MARK: - UIKit

    public init(
		headerView: SegmentHeaderView? = nil,
		navigationBar: SegmentNavigationBarView,
        viewControllers: [SegmentContentViewController],
		initialIndex: Int = 0
    ) {
		self.headerView = headerView
		self.viewControllers = viewControllers
		self.navigationBar = navigationBar
		self.initialIndex = initialIndex

		assert(viewControllers.isEmpty == false, "ViewControlles mustn't be empty")
		assert((initialIndex > viewControllers.count) == false, "Initial index mustn't be more than controlles count")
		super.init(nibName: nil, bundle: nil)

		self.headerView?.delegate = self
		self.navigationBar.delegate = self
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

		$contentState.listen { [weak self] in
			self?.segmentDidRefreshFinished()
		}

		self.viewControllers.forEach {
			$0.$contentState.listen { [weak self] in self?.segmentDidRefreshFinished() }
			$0.$isAvailable.listen { [weak self] in self?.pageCollectionView.invalidate() }

			$0.delegate = self

			if self.headerView != nil {
				$0.segmentScrollView().bounces = false
			}
		}

		self.view.addSubview(self.verticalCollectionView)

		NSLayoutConstraint.activate([
			self.verticalCollectionView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
			self.verticalCollectionView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
			self.verticalCollectionView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
			self.verticalCollectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
		])

		self.pageCollectionView.scrollToItem(at: self.initialIndex, animated: false)

		DispatchQueue.main.async {
			UIView.setAnimationsEnabled(false)
			self.navigationBar.segment(didScroll: CGFloat(self.initialIndex))
			UIView.setAnimationsEnabled(true)
		}
    }

	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		guard self.backGesture == nil else { return }
		self.pageCollectionView.horziontalScrollView.map { scrollView in
			self.navigationController?.interactivePopGestureRecognizer.map {
				let targets = $0.value(forKey: "targets") as? NSMutableArray
				let panGesture = UIPanGestureRecognizer()
				panGesture.setValue(targets, forKey: "targets")
				panGesture.delegate = self
				scrollView.addGestureRecognizer(panGesture)
				self.backGesture = panGesture
			}
		}
	}

	open func segmentDidRefreshFinished() {}

	// Handlers

	var _onDidSelectIndexFallback: ((Int) -> Void)?

	public func onDidSelectIndexFallback(_ handler: @escaping (Int) -> Void) {
		self._onDidSelectIndexFallback = handler
	}

	// Helpers

	public func addRefreshControl(_ completion: (UIScrollView) -> Void) {
		self.verticalCollectionView.addRefreshControl(completion)
	}

	public func unwrapContentState() -> SegmentContentState {
		let isCurrentFirst = (self.viewControllers.firstIndex(of: self.currentViewController) ?? 0) == 0
		switch (self.currentViewController.contentState, self.contentState) {
		case let (.loading(controllerWithContent), .loading(headerWithContent)):
			return .loading(withContent: ((isCurrentFirst ? controllerWithContent : true) && headerWithContent))

		case let (.loading(controllerWithContent), .normal):
			return .loading(withContent: (isCurrentFirst ? controllerWithContent : true))

		case let (.normal, .loading(headerWithContent)):
			return .loading(withContent: headerWithContent)

		case (.normal, .normal):
			return .normal

		case let (.error(error), .loading),
			let (.error(error), .normal),
			let (.loading, .error(error)),
			let (.normal, .error(error)),
			let (.error, .error(error)):
			return .error(error)
		}
	}

	public func enableHorizontalScroll(_ value: Bool) {
		self.pageCollectionView.enableHorizontalScroll()
	}

	public func selectSegment(at index: Int) {
		self.navigationBar.selectSegment(at: index)
	}

	public func scrollToTop(animated: Bool) {
		self.currentViewController.segmentScrollView().setContentOffset(.zero, animated: animated)
		self.verticalCollectionView.scrollToTop(animated: animated)
	}
}

extension SegmentContainerViewController: SegmentHeaderDelegate {
	public func segmentHeaderReload() {
		UIView.performWithoutAnimation {
			self.verticalCollectionView.reloadItem(at: IndexPath(item: 0, section: 0))
		}
	}
}

extension SegmentContainerViewController: SegmentNavigationBarDelegate
{
    func segmentNavigationBar(didSelect item: Int) {
        self.pageCollectionView.scrollToItem(at: item, animated: true)
        self.syncCollaborativeScrollIfNeeded()
    }

	func segmentNavigationBar(shouldSelect item: Int) -> Bool {
		let isAvailable = self.viewControllers[item].isAvailable
		if isAvailable == false { self._onDidSelectIndexFallback?(item) }
		return isAvailable
	}
}

extension SegmentContainerViewController: SegmentVerticalCollectionAdapter
{
    func segmentVerticalCollection(headerView collectionView: UICollectionView) -> UIView? {
		self.headerView
    }

    func segmentVerticalCollection(navigationBarView collectionView: UICollectionView) -> UIView? {
        guard self.viewControllers.count > 1 else { return nil }
        return self.navigationBar
    }

    func segmentVerticalCollection(pageCollectionView collectionView: UICollectionView) -> UIView {
        self.pageCollectionView
    }

    func segmentVerticalCollection(didScroll collectionView: UICollectionView) {
        self.syncVerticalScrollIfNeeded()
    }
}

extension SegmentContainerViewController: SegmentPageCollectionAdapter
{
    func segmentPageCollection(isAvailable index: Int) -> Bool {
        self.viewControllers[index].isAvailable
    }

    func segmentPageCollectionViewControllers() -> [UIViewController] {
        self.viewControllers
    }

    func segmentPageCollectionWillBeginDragging() {
        self.viewControllers.forEach {
            $0.segmentScrollView().isScrollEnabled = false
        }
        self.syncCollaborativeScrollIfNeeded()
    }

    func segmentPageCollectionDidEndDragging() {
        self.viewControllers.forEach {
            $0.segmentScrollView().isScrollEnabled = true
        }
    }

    func segmentPageCollection(didScroll point: CGPoint) {
		self.navigationBar.segment(didScroll: (point.x / self.view.frame.width) - 1)
    }
}

extension SegmentContainerViewController: SegmentContentDelegate
{
    public func segmentContent(didScroll scrollView: UIScrollView) {
        self.syncVerticalScrollIfNeeded()
    }
}

extension SegmentContainerViewController: UIGestureRecognizerDelegate
{
	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer,
			  panRecognizer == self.backGesture
		else {
			return true
		}

		guard let gestureView = panRecognizer.view else { return true }

		let velocity = panRecognizer.velocity(in: gestureView).x

		guard velocity > 0 else { return false }

		guard self.pageCollectionView.hasViewControllerBefore() else { return false }

		return true
	}

	public func gestureRecognizer(
		_ gestureRecognizer: UIGestureRecognizer,
		shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
	) -> Bool {
		gestureRecognizer == self.backGesture &&
		otherGestureRecognizer == self.pageCollectionView.horziontalScrollView?.panGestureRecognizer
	}
}

// MARK: - Private

private extension SegmentContainerViewController
{
    func syncVerticalScrollIfNeeded() {
        guard self.headerView != nil else {
            self.verticalCollectionView.contentOffsetY = 0
            return
        }

        let ctx = (
            headerViewH: self.verticalCollectionView.sizeForHeader().height,
            verticalY: self.verticalCollectionView.contentOffsetY,
            lastVerticalY: self.verticalCollectionView.lastContentOffsetY,
            collaborativeY: self.visibleCollaborativeScrollView.contentOffset.y
        )

        let collaborativeY = ctx.verticalY >= ctx.headerViewH
            ? ctx.collaborativeY
            : ctx.collaborativeY > 0 && ctx.lastVerticalY >= ctx.headerViewH
            ? ctx.collaborativeY
            : 0

        let verticalY = collaborativeY > 0
            ? ctx.headerViewH
            : ctx.verticalY

		let contentOffsetY = max(0, collaborativeY)

        self.visibleCollaborativeScrollView.contentOffset.y = contentOffsetY
		self.visibleCollaborativeScrollView.bounces = contentOffsetY > 100
        self.verticalCollectionView.contentOffsetY = min(ctx.headerViewH, verticalY)
        self.verticalCollectionView.lastContentOffsetY = min(ctx.headerViewH, verticalY)
        self.lastCollaborativeScrollView = self.visibleCollaborativeScrollView
    }

    func syncCollaborativeScrollIfNeeded() {
        guard let collaborativeScrollView = self.lastCollaborativeScrollView,
              self.headerView != nil
        else {
            return
        }

        let ctx = (
            collaborativeY: collaborativeScrollView.contentOffset.y,
			navBarHeight: self.navigationBar.segmentHeight()
        )

        self.viewControllers
            .map { $0.segmentScrollView() }
            .filter { $0 != collaborativeScrollView }
            .forEach {
                if ctx.collaborativeY == 0 && $0.contentOffset.y > 0 { $0.contentOffset.y = 0 }
            }
    }
}