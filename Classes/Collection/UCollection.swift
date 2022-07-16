#if !os(macOS)
import UIKit

public struct UCollectionStub: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public enum UCollectionState<T>: Equatable {
    case loading
    case data(T)
    case empty
    case stub(UCollectionStub)
	case error(Error)

	public var data: T? {
		guard case let .data(data) = self else { return nil }
		return data
	}

    public var isStub: Bool {
        guard case .stub = self else { return false }
        return true
    }

    public var isData: Bool {
        guard case .data = self else { return false }
        return true
    }

	public var isError: Bool {
		guard case .error = self else { return false }
		return true
	}

	public var isLoading: Bool {
		guard case .loading = self else { return false }
		return true
	}

	public var isEmpty: Bool {
		guard case .empty = self else { return false }
		return true
	}

    public static func == (lhs: UCollectionState<T>, rhs: UCollectionState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.data, .data): return true
        case (.empty, .empty): return true
        case (.stub, .stub): return true
		case (.error, .error): return true
        default: return false
        }
    }
}

open class UCollection: UView {
    public enum Configuration {
        case defaut
        case layout(UICollectionViewLayout)
        case custom(UICollectionView)

        var collectionView: UICollectionView {
            switch self {
            case .defaut: return UCollectionView(UCollectionView.defaultLayout)
            case let .layout(layout): return UCollectionView(layout)
            case let .custom(collectionView): return collectionView
            }
        }
    }

    public struct Section: Hashable {
		public let identifier: USection.Identifier
		public let header: USupplementable?
		public var items: [UItemable]
		public let footer: USupplementable?
        
        init(_ section: USection) {
            self.identifier = section.identifier
            self.header = section.header
            self.items = section.items
            self.footer = section.footer
        }
        
        public static func == (lhs: Section, rhs: Section) -> Bool {
            lhs.identifier == rhs.identifier
                && lhs.header?.identifier == rhs.header?.identifier
                && lhs.items.map { $0.identifier } == rhs.items.map { $0.identifier }
                && lhs.footer?.identifier == rhs.footer?.identifier
        }
        
        public func hash(into hasher: inout Hasher) {
            self.identifier.hash(into: &hasher)
            self.header?.identifier.hash(into: &hasher)
            self.items.map { $0.identifier }.hash(into: &hasher)
            self.footer?.identifier.hash(into: &hasher)
        }
    }

    lazy var collectionView: UICollectionView = {
        let collectionView = self.configuration.collectionView
        collectionView.register(UCollectionDynamicCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.prefetchDataSource = self
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    var collectionViewOriginalSize: CGSize {
        let size = self.collectionView.frame.size
        let contentInset = self.collectionView.contentInset
		let safeInset = self.isSafeAreaIncluded ? self.collectionView.safeInsets : .zero
        return CGSize(
            width: size.width - (contentInset.left + contentInset.right) - (safeInset.left + safeInset.right),
            height: size.height - (contentInset.top + contentInset.bottom) - (safeInset.top + safeInset.bottom)
        )
    }

	var direction: UICollectionView.ScrollDirection {
		(self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection ?? .vertical
	}
    
    public private(set) var sections: [Section] = [] {
        didSet { self.updateRegistration() }
    }
    
    var scrollPosition: State<CGPoint>?
    var changesPool = 0
    var isChanging = false
    var isInitialized = false
	var reversed = false
	var isSafeAreaIncluded = true
    
    let configuration: Configuration
    let items: [USectionItemable]

    public init<T>(
        _ configuration: Configuration = .defaut,
        _ state: State<UCollectionState<T>>,
        @CollectionBuilder<USectionItemable> block: @escaping (UCollectionState<T>) -> [USectionItemable]
    ) {
        self.configuration = configuration
        self.items = [USectionMap(state, block: block)]
        super.init(frame: .zero)
        self.items.forEach { self.process($0) }
    }

    public init<T>(
        _ configuration: Configuration = .defaut,
        _ state: State<UCollectionState<T>>,
        @CollectionBuilder<USectionBodyItemable> block: @escaping (UCollectionState<T>) -> [USectionBodyItemable]
    ) {
        self.configuration = configuration
        self.items = [
            USectionMap(state) {
                USection(identifier: 0, body: block($0))
            },
        ]
        super.init(frame: .zero)
        self.items.forEach { self.process($0) }
    }

    public init (
        _ configuration: Configuration = .defaut,
        @CollectionBuilder<USectionItemable> block: () -> [USectionItemable]
    ) {
        self.configuration = configuration
        self.items = block()
        super.init(frame: .zero)
        self.items.forEach { self.process($0) }
    }
    
    public init (
        _ configuration: Configuration = .defaut,
        @CollectionBuilder<USectionBodyItemable> block: () -> [USectionBodyItemable]
    ) {
        self.configuration = configuration
        self.items = [USection(identifier: 0, body: block())]
        super.init(frame: .zero)
        self.items.forEach { self.process($0) }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	open override func didMoveToWindow() {
		super.didMoveToWindow()
		guard self.isInitialized == false else { return }
		self.isInitialized = true
		DispatchQueue.main.async { self.reloadData() }
	}
    
    override public func buildView() {
        super.buildView()
		body { collectionView }
		collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])
    }
    
    // MARK: - Handlers
    
    var _willDisplay: ((UICollectionView, UICollectionViewCell, IndexPath) -> Void)?
    
    public func onWillDisplay(_ handler: @escaping (UICollectionView, UICollectionViewCell, IndexPath) -> Void) -> Self {
        self._willDisplay = handler
        return self
    }

	var _didEndDisplay: ((UICollectionView, UICollectionViewCell, IndexPath) -> Void)?

	public func onDidEndDisplay(_ handler: @escaping (UICollectionView, UICollectionViewCell, IndexPath) -> Void) -> Self {
		self._didEndDisplay = handler
		return self
	}
    
    var _didSelectItemAt: ((UICollectionView, IndexPath) -> Void)?
    
    public func onDidSelectItemAt(_ handler: @escaping (UICollectionView, IndexPath) -> Void) -> Self {
        self._didSelectItemAt = handler
        return self
    }

    var _didDeselectItemAt: ((UICollectionView, IndexPath) -> Void)?

    public func onDidDeselectItemAt(_ handler: @escaping (UICollectionView, IndexPath) -> Void) -> Self {
        self._didDeselectItemAt = handler
        return self
    }

    var _didHighlightItemAt: ((UICollectionView, IndexPath) -> Void)?

    public func onDidHighlightItemAt(_ handler: @escaping (UICollectionView, IndexPath) -> Void) -> Self {
        self._didHighlightItemAt = handler
        return self
    }

    var _didUnhighlightItemAt: ((UICollectionView, IndexPath) -> Void)?

    public func onUnhighlightItemAt(_ handler: @escaping (UICollectionView, IndexPath) -> Void) -> Self {
        self._didUnhighlightItemAt = handler
        return self
    }
    
    var _shouldHighlightItemAt: ((UICollectionView, IndexPath) -> Bool)?
    
    public func onShouldHighlightItemAt(_ handler: @escaping (UICollectionView, IndexPath) -> Bool) -> Self {
        self._shouldHighlightItemAt = handler
        return self
    }

	var _scrollViewDidScroll: ((UICollectionView) -> Void)?

	public func onScrollViewDidScroll(_ handler: @escaping (UICollectionView) -> Void) -> Self {
		self._scrollViewDidScroll = handler
		return self
	}

	var _scrollViewDidEndDecelerating: ((UICollectionView) -> Void)?

	public func onScrollViewDidEndDecelerating(_ handler: @escaping (UICollectionView) -> Void) -> Self {
		self._scrollViewDidEndDecelerating = handler
		return self
	}

	var _scrollViewDidEndDragging: ((UICollectionView, Bool) -> Void)?

	public func onScrollViewDidEndDragging(_ handler: @escaping (UICollectionView, Bool) -> Void) -> Self {
		self._scrollViewDidEndDragging = handler
		return self
	}

	var _onPerformDrop: ((UICollectionView, IndexPath, IndexPath) -> Void)?

	public func onPerformDrop(_ handler: @escaping (UICollectionView, IndexPath, IndexPath) -> Void) -> Self {
		self._onPerformDrop = handler
		return self
	}

	var _prefetchItemsAt: ((UICollectionView, [IndexPath]) -> Void)?

	public func onPrefetchItemsAt(_ handler: @escaping (UICollectionView, [IndexPath]) -> Void) -> Self {
		self._prefetchItemsAt = handler
		return self
	}

	var _cancelPrefetchingForItemsAt: ((UICollectionView, [IndexPath]) -> Void)?

	public func onCancelPrefetchingForItemsAt(_ handler: @escaping (UICollectionView, [IndexPath]) -> Void) -> Self {
		self._cancelPrefetchingForItemsAt = handler
		return self
	}

	var _onCompleteBatchUpdates: (() -> Void)?

	public func onCompleteBatchUpdates(_ handler: @escaping () -> Void) -> Self {
		self._onCompleteBatchUpdates = handler
		return self
	}

	// MARK: - Layout

	var _sectionInset: ((USection.Identifier) -> UIEdgeInsets?)?

	public func sectionInset(_ handler: @escaping (USection.Identifier) -> UIEdgeInsets?) -> Self {
		self._sectionInset = handler
		return self
	}

	var _minimumLineSpacing: ((USection.Identifier) -> CGFloat?)?

	public func minimumLineSpacing(_ handler: @escaping (USection.Identifier) -> CGFloat?) -> Self {
		self._minimumLineSpacing = handler
		return self
	}

	var _minimumInteritemSpacing: ((USection.Identifier) -> CGFloat?)?

	public func minimumInteritemSpacing(_ handler: @escaping (USection.Identifier) -> CGFloat?) -> Self {
		self._minimumInteritemSpacing = handler
		return self
	}

    // MARK: - Helpers

    public func scrollToItem(_ indexPath: IndexPath, at position: UICollectionView.ScrollPosition, offset: CGPoint = .zero, animated: Bool = true) {
		guard self.isInitialized else { return }

        guard offset != .zero else {
            self.collectionView.scrollToItem(at: indexPath, at: position, animated: animated)
            return
        }

        let attributes = self.collectionView.layoutAttributesForItem(at: indexPath)

        guard let frame = attributes?.frame.offsetBy(dx: offset.x, dy: offset.y) else {
            self.collectionView.scrollToItem(at: indexPath, at: position, animated: animated)
            return
        }

        switch position {
        case .bottom: self.collectionView.setContentOffset(.init(x: frame.minX, y: frame.maxY), animated: animated)
        case .top: self.collectionView.setContentOffset(.init(x: frame.minX, y: frame.minY), animated: animated)
        case .left: self.collectionView.setContentOffset(.init(x: frame.minX, y: frame.minY), animated: animated)
        case .right: self.collectionView.setContentOffset(.init(x: frame.maxX, y: frame.minY), animated: animated)
        case .centeredHorizontally: self.collectionView.setContentOffset(.init(x: frame.midX, y: frame.minY), animated: animated)
        case .centeredVertically: self.collectionView.setContentOffset(.init(x: frame.minX, y: frame.midY), animated: animated)
        default: self.collectionView.scrollToItem(at: indexPath, at: position, animated: animated)
        }
    }

    @discardableResult
    public func itCollection(_ collection: inout UICollectionView?) -> Self {
        collection = self.collectionView
        return self
    }

    @discardableResult
    public func scrolling(_ enabled: Bool) -> Self {
        self.collectionView.isScrollEnabled = enabled
        return self
    }

	@discardableResult
	public func paging(_ enabled: Bool) -> Self {
		self.collectionView.isPagingEnabled = enabled
		return self
	}

	@discardableResult
	public func dragDrop(_ enabled: Bool) -> Self {
		self.collectionView.dragInteractionEnabled = enabled
		return self
	}

	@discardableResult
	public func includeSafeArea(_ value: Bool) -> Self {
		self.isSafeAreaIncluded = value
		return self
	}
}

extension UCollection {
    func process(_ section: USectionItemable) {
        switch section.sectionItem {
        case let .single(section):
            section.body.forEach { self.process($0) }
        case let .map(mp):
            mp.allItems().forEach { self.process($0) }
            mp.subscribeToChanges { [weak self] in self?.reloadData()  }
        case let .multiple(items):
            items.forEach { self.process($0) }
        }
    }
    
    func process(_ item: USectionBodyItemable) {
        switch item.sectionBodyItem {
        case let .map(mp):
            mp.allItems().forEach { self.process($0) }
            mp.subscribeToChanges { [weak self] in self?.reloadData() }
        case let .multiple(items):
            items.forEach { self.process($0) }
        default:
            break
        }
    }
    
    func reloadData() {
        guard self.isInitialized else { return }

        if self.isChanging {
            self.changesPool += 1
            return
        }
        
        self.isChanging = true
        
        let newSections = self.items
            .map { self.unwrapSections($0) }
            .flatMap { $0 }
            .map { Section($0) }
            .filter { $0.items.isEmpty == false }
        
        if self.sections.isEmpty {
            self.sections = newSections
            self.collectionView.reloadData()
            self.isChanging = false
            return
        }

		let changeset = SectionedChangeset(
			previous: self.sections,
			current: newSections,
			sectionIdentifier: { (section: Section) -> AnyHashable in section.identifier },
			areMetadataEqual: { (first: Section, second: Section) -> Bool in
				first.header?.identifier == second.header?.identifier &&
				first.footer?.identifier == second.footer?.identifier
			},
			items: { (section: Section) -> [UItemable] in section.items },
			itemIdentifier: { (item: UItemable) -> AnyHashable in item.identifier },
			areItemsEqual: { (first: UItemable, second: UItemable) -> Bool in first.isEqual(to: second) }
		)

		self.collectionView.performBatchUpdates({
			self.sections = newSections

			self.collectionView.deleteSections(changeset.sections.removals)
			self.collectionView.insertSections(changeset.sections.inserts)
			self.collectionView.reloadSections(changeset.sections.mutations)

			for move in changeset.sections.moves {
				self.collectionView.moveSection(move.source, toSection: move.destination)
			}

			for mutatedSection in changeset.mutatedSections {
				var deleted = mutatedSection.changeset.removals.sorted(by: >).map { IndexPath(item: $0, section: mutatedSection.source) }
				var inserted = mutatedSection.changeset.inserts.sorted(by: <).map { IndexPath(item: $0, section: mutatedSection.destination) }
				var mutated = mutatedSection.changeset.mutations.map { IndexPath(item: $0, section: mutatedSection.destination) }

				if mutatedSection.changeset.removals == mutatedSection.changeset.inserts {
					mutated.append(contentsOf: inserted)
					deleted = []
					inserted = []
				}

				self.collectionView.deleteItems(at: deleted)
				self.collectionView.insertItems(at: inserted)
				DispatchQueue.main.async {
					self.collectionView.reloadItems(at: mutated)
				}

				for move in mutatedSection.changeset.moves {
					let from = IndexPath(item: move.source, section: mutatedSection.source)
					let to = IndexPath(item: move.destination, section: mutatedSection.destination)
					self.collectionView.moveItem(at: from, to: to)
				}
			}
		}, completion: { _ in
			self.isChanging = false
			if self.changesPool > 0 {
				self.changesPool -= 1
				self.reloadData()
			}
			else {
				self._onCompleteBatchUpdates?()
			}
		})
    }
    
    func updateRegistration() {
        self.sections.forEach {
            _ = $0.header.map { self.collectionView.register($0.viewClass, UICollectionView.elementKindSectionHeader) }
            $0.items.forEach { self.collectionView.register($0.cellClass) }
            _ = $0.footer.map { self.collectionView.register($0.viewClass, UICollectionView.elementKindSectionFooter) }
        }
		self.collectionView.register(UCollectionCell.self)
    }
    
    func unwrapSections(_ item: USectionItemable) -> [USection] {
        switch item.sectionItem {
        case let .single(section): return [section]
        case let .map(mp): return mp.allItems().map { self.unwrapSections($0) }.flatMap { $0 }
        case let .multiple(items): return items.map { self.unwrapSections($0) }.flatMap { $0 }
        }
    }
}

extension UCollection: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        self.sections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard self.sections.indices.contains(section) else { return 0 }
        return self.sections[section].items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let item = self.item(for: indexPath) else { return collectionView.dequeueReusableCell(with: UCollectionCell.self, for: indexPath) }
        let cell = item.generate(collectionView: collectionView, for: indexPath)
		cell.transform = CGAffineTransform(rotationAngle: self.reversed ? CGFloat(Double.pi) : 0)
		return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		guard self.sections.indices.contains(indexPath.section) else { return UICollectionReusableView() }
		let view: UICollectionReusableView
		switch kind {
		case UICollectionView.elementKindSectionHeader:
			view = self.sections[indexPath.section].header?.generate(collectionView: collectionView, kind: kind, for: indexPath) ?? UICollectionReusableView()
		case UICollectionView.elementKindSectionFooter:
			view = self.sections[indexPath.section].footer?.generate(collectionView: collectionView, kind: kind, for: indexPath) ?? UICollectionReusableView()
		default:
			view = UICollectionReusableView()
		}
		view.transform = CGAffineTransform(rotationAngle: self.reversed ? CGFloat(Double.pi) : 0)
		return view
    }
}

extension UCollection: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		guard let item = self.item(for: indexPath) else { return .zero }
        guard self.collectionViewOriginalSize.width > 0 && self.collectionViewOriginalSize.height > 0 else { return .zero }
		let sectionInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
		let collectionSize = self.collectionViewOriginalSize
		let size = CGSize(width: collectionSize.width - (sectionInset.left + sectionInset.right), height: collectionSize.height - (sectionInset.top + sectionInset.bottom))
		return item.size(by: size, direction: self.direction)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		guard self.sections.indices.contains(section) else { return .zero }
        guard self.collectionViewOriginalSize.width > 0 && self.collectionViewOriginalSize.height > 0 else { return .zero }
		let sectionInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
		let collectionSize = self.collectionViewOriginalSize
		let size = CGSize(width: collectionSize.width - (sectionInset.left + sectionInset.right), height: collectionSize.height - (sectionInset.top + sectionInset.bottom))
        return self.sections[section].header?.size(by: size, direction: self.direction) ?? .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		guard self.sections.indices.contains(section) else { return .zero }
        guard self.collectionViewOriginalSize.width > 0 && self.collectionViewOriginalSize.height > 0 else { return .zero }
		let sectionInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
		let collectionSize = self.collectionViewOriginalSize
		let size = CGSize(width: collectionSize.width - (sectionInset.left + sectionInset.right), height: collectionSize.height - (sectionInset.top + sectionInset.bottom))
        return self.sections[section].footer?.size(by: size, direction: self.direction) ?? .zero
    }

	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		guard self.sections.indices.contains(section) else { return .zero }
		let sectionInset = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
		let customSectionInset = self._sectionInset?(self.sections[section].identifier)
		return customSectionInset ?? sectionInset
	}

	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		guard self.sections.indices.contains(section) else { return .zero }
		let minimumLineSpacing = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? .zero
		let customMinimumLineSpacing = self._minimumLineSpacing?(self.sections[section].identifier)
		return customMinimumLineSpacing ?? minimumLineSpacing
	}

	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		guard self.sections.indices.contains(section) else { return .zero }
		let minimumInteritemSpacing = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? .zero
		let customMinimumInteritemSpacing = self._minimumInteritemSpacing?(self.sections[section].identifier)
		return customMinimumInteritemSpacing ?? minimumInteritemSpacing
	}
}

extension UCollection: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self._willDisplay?(collectionView, cell, indexPath)
        (self.item(for: indexPath) as? UItemableDelegate)?.willDisplay()
    }

	public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		self._didEndDisplay?(collectionView, cell, indexPath)
		(self.item(for: indexPath) as? UItemableDelegate)?.didEndDisplay()
	}
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self._didSelectItemAt?(collectionView, indexPath)
		(self.item(for: indexPath) as? UItemableDelegate)?.didSelect()
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self._didDeselectItemAt?(collectionView, indexPath)
		(self.item(for: indexPath) as? UItemableDelegate)?.didDeselect()
    }

    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        self._didHighlightItemAt?(collectionView, indexPath)
		(self.item(for: indexPath) as? UItemableDelegate)?.didHighlight()
    }

    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        self._didUnhighlightItemAt?(collectionView, indexPath)
		(self.item(for: indexPath) as? UItemableDelegate)?.didUnhighlight()
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        self._shouldHighlightItemAt?(collectionView, indexPath) ?? true
    }
}

extension UCollection: UIScrollViewDelegate {
    @discardableResult
    public func contentOffset(_ position: CGPoint, animated: Bool = true) -> Self {
        self.collectionView.setContentOffset(position, animated: animated)
        return self
    }
    
    @discardableResult
    public func scrollPosition(_ binding: UISwift.State<CGPoint>) -> Self {
        self.scrollPosition = binding
        return self
    }

    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollPosition?.wrappedValue = scrollView.contentOffset
		self._scrollViewDidScroll?(self.collectionView)
    }

	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		self._scrollViewDidEndDecelerating?(self.collectionView)
	}

	public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		self._scrollViewDidEndDragging?(self.collectionView, decelerate)
	}
}

extension UCollection: UICollectionViewDragDelegate {
	public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		guard let item = self.item(for: indexPath), (item as? UItemableDrag)?.canDrag == true else { return [] }
		let itemProvider = NSItemProvider(object: "\(item.identifier.hashValue)" as NSString)
		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = item
		return [dragItem]
	}
}

extension UCollection: UICollectionViewDropDelegate {
	public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		if collectionView.hasActiveDrag {
			return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
		}
		return UICollectionViewDropProposal(operation: .forbidden)
	}


	public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		guard coordinator.proposal.operation == .move,
			  let item = coordinator.items.first,
			  let sourceIndexPath = item.sourceIndexPath,
			  let destanationIndexPath = coordinator.destinationIndexPath
		else {
			return
		}
		self._onPerformDrop?(collectionView, sourceIndexPath, destanationIndexPath)
		coordinator.drop(item.dragItem, toItemAt: destanationIndexPath)
	}
}

extension UCollection: UICollectionViewDataSourcePrefetching {
	public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		self._prefetchItemsAt?(collectionView, indexPaths)
	}

	public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
		self._cancelPrefetchingForItemsAt?(collectionView, indexPaths)
	}
}

extension UCollection {
    @available(iOS 11.0, *)
    @discardableResult
    public func contentInsetAdjustmentBehavior(_ value: UIScrollView.ContentInsetAdjustmentBehavior) -> Self {
        self.collectionView.contentInsetAdjustmentBehavior = value
        return self
    }

    @discardableResult
    public func keyboardDismissMode(_ mode: UIScrollView.KeyboardDismissMode) -> Self {
        self.collectionView.keyboardDismissMode = mode
        return self
    }
    
    @discardableResult
    public func refreshControl(_ refreshControl: UIRefreshControl) -> Self {
        if #available(iOS 10.0, *) {
            self.collectionView.refreshControl = refreshControl
        } else {
            self.collectionView.addSubview(refreshControl)
        }
        return self
    }

	@discardableResult
	public func bounces(_ value: Bool = true) -> Self {
		self.collectionView.bounces = value
		return self
	}
    
    @discardableResult
    public func alwaysBounceVertical(_ value: Bool = true) -> Self {
        self.collectionView.alwaysBounceVertical = value
        return self
    }

    @discardableResult
    public func alwaysBounceHorizontal(_ value: Bool = true) -> Self {
        self.collectionView.alwaysBounceHorizontal = value
        return self
    }
    
    // MARK: Indicators
    
    @discardableResult
    public func hideIndicator(_ indicators: NSLayoutConstraint.Axis...) -> Self {
        if indicators.contains(.horizontal) {
            self.collectionView.showsHorizontalScrollIndicator = false
        }
        if indicators.contains(.vertical) {
            self.collectionView.showsVerticalScrollIndicator = false
        }
        return self
    }
    
    // MARK: Indicators
    
    @discardableResult
    public func hideAllIndicators() -> Self {
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.showsVerticalScrollIndicator = false
        return self
    }
    
    // MARK: Content Inset
    
    @discardableResult
    public func contentInset(_ insets: UIEdgeInsets) -> Self {
        self.collectionView.contentInset = insets
        return self
    }
    
    @discardableResult
    public func contentInset(top: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0, bottom: CGFloat = 0) -> Self {
        self.contentInset(.init(top: top, left: left, bottom: bottom, right: right))
    }
    
    // MARK: Scroll Indicator Inset
    
    @discardableResult
    public func scrollIndicatorInsets(_ insets: UIEdgeInsets) -> Self {
        self.collectionView.scrollIndicatorInsets = insets
        return self
    }
    
    @discardableResult
    public func scrollIndicatorInsets(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> Self {
        self.scrollIndicatorInsets(.init(top: top, left: left, bottom: bottom, right: right))
    }

	@discardableResult
	public func reversed(_ value: Bool = true) -> Self {
		self.reversed = value
		self.collectionView.transform = CGAffineTransform(rotationAngle: value ? -(CGFloat)(Double.pi) : 0)
		self.collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: self.collectionView.bounds.size.width - 8)
		return self
	}

	public func item(for indexPath: IndexPath) -> UItemable? {
		guard self.sections.indices.contains(indexPath.section) && self.sections[indexPath.section].items.indices.contains(indexPath.item) else {
			return nil
		}
		return self.sections[indexPath.section].items[indexPath.item]
	}
}
#endif
