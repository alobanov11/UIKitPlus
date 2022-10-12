//
//  Created by Антон Лобанов on 13.03.2021.
//

import UIKit

protocol SegmentVerticalCollectionAdapter: AnyObject {
    func segmentVerticalCollectionHeader() -> UIView?
    func segmentVerticalCollectionNavigationBar() -> UIView?
    func segmentVerticalCollectionPageCollection() -> UIView
    func segmentVerticalCollectionDidScroll()
}

final class SegmentVerticalCollectionView: UView {
    private final class ControlContainableCollectionView: UCollaborativeCollectionView
    {
        override func touchesShouldCancel(in view: UIView) -> Bool {
            return view.isKind(of: UIControl.self) ? true : super.touchesShouldCancel(in: view)
        }
    }

    var lastContentOffsetY: CGFloat = 0

    var contentOffsetY: CGFloat {
        get { self.verticalCollectionView.contentOffset.y }
        set { self.verticalCollectionView.contentOffset.y = newValue }
    }

	var isScrollEnabled: Bool {
		get { self.verticalCollectionView.isScrollEnabled }
		set { self.verticalCollectionView.isScrollEnabled = newValue }
	}

    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        return layout
    }()

    private lazy var verticalCollectionView: UICollectionView = {
        let collectionView = ControlContainableCollectionView(
            frame: .zero,
            collectionViewLayout: self.flowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
		collectionView.bounces = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self

		if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }

		collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self)
        )

		return collectionView
    }()

    private weak var adapter: SegmentVerticalCollectionAdapter!

    init(adapter: SegmentVerticalCollectionAdapter) {
        self.adapter = adapter

		super.init(frame: .zero)

		self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.verticalCollectionView)
        NSLayoutConstraint.activate([
            self.verticalCollectionView.topAnchor.constraint(equalTo: self.topAnchor),
            self.verticalCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.verticalCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.verticalCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadItem(at indexPath: IndexPath) {
        self.verticalCollectionView.performBatchUpdates({
            self.verticalCollectionView.reloadItems(at: [indexPath])
        }, completion: { _ in })
    }

    func sizeForHeader() -> CGSize {
		self.sizeForItem(IndexPath(item: 0, section: 0))
    }

	func addRefreshControl(_ completion: (UIScrollView) -> Void) {
		completion(self.verticalCollectionView)
	}

	func scrollToTop(animated: Bool) {
		self.verticalCollectionView.setContentOffset(.zero, animated: animated)
	}
}

extension SegmentVerticalCollectionView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        4
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: UICollectionViewCell.self),
            for: indexPath
        )

        let contentView: UIView

        switch true {
        case indexPath.item == 0:
            let headerView = self.adapter.segmentVerticalCollectionHeader()
            contentView = headerView ?? UIView()
        case indexPath.item == 1:
            let navigationBarView = self.adapter.segmentVerticalCollectionNavigationBar()
            contentView = navigationBarView ?? UIView()
        case indexPath.item == 2:
            let pageCollectionView = self.adapter.segmentVerticalCollectionPageCollection()
            contentView = pageCollectionView
        default:
            contentView = UIView()
        }

        contentView.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.addSubview(contentView)
        cell.contentView.clipsToBounds = true

        let bottomConstraint = NSLayoutConstraint(item: contentView,
                                                  attribute: .bottom,
                                                  relatedBy: .equal,
                                                  toItem: cell.contentView,
                                                  attribute: .bottom,
                                                  multiplier: 1,
                                                  constant: 0)
        bottomConstraint.priority = .init(999)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            bottomConstraint,
        ])

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
		self.sizeForItem(indexPath)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
		guard scrollView.isDragging || scrollView.isTracking else { return }
        self.adapter.segmentVerticalCollectionDidScroll()
    }
}

private extension SegmentVerticalCollectionView {
	func sizeForItem(_ indexPath: IndexPath) -> CGSize {
		switch true {
		case indexPath.item == 0:
			let headerView = self.adapter.segmentVerticalCollectionHeader()
			return headerView?.systemLayoutSizeFitting(
				.init(width: self.frame.width, height: 0),
				withHorizontalFittingPriority: .required,
				verticalFittingPriority: .fittingSizeLevel
			) ?? .zero
		case indexPath.item == 1:
			let navigationBarView = self.adapter.segmentVerticalCollectionNavigationBar()
			return navigationBarView?.systemLayoutSizeFitting(
				.init(width: self.frame.width, height: 0),
				withHorizontalFittingPriority: .required,
				verticalFittingPriority: .fittingSizeLevel
			) ?? .zero
		case indexPath.item == 2:
			let navigationBarHeight = self.sizeForItem(IndexPath(item: 1, section: 0)).height
			return self.verticalCollectionView.frame.size.height > 0 ? .init(
				width: self.verticalCollectionView.frame.width,
				height: self.verticalCollectionView.frame.size.height - navigationBarHeight
			) : .zero
		default:
			return .zero
		}
	}
}
