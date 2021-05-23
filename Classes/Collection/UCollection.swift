#if !os(macOS)
import UIKit

open class UCollection: UView {
    struct Section: Identable {
        static var idKey: KeyPath<Self, AnyHashable> {
            \.identifier
        }

        let identifier: AnyHashable
        let header: USupplementable?
        let items: [UItemable]
        let footer: USupplementable?

        init(_ section: USection) {
            self.identifier = section.identifier
            self.header = section.header
            self.items = section.items
            self.footer = section.footer
        }

        public static func == (lhs: Section, rhs: Section) -> Bool {
            lhs.header?.identifier == rhs.header?.identifier
                && lhs.items.map { $0.identifier } == rhs.items.map { $0.identifier }
                && lhs.footer?.identifier == rhs.footer?.identifier
        }

        public func hash(into hasher: inout Hasher) {
            self.header?.identifier.hash(into: &hasher)
            self.items.map { $0.identifier }.hash(into: &hasher)
            self.footer?.identifier.hash(into: &hasher)
        }
    }

    enum Changeset {
        case section(SectionChanges)
        case items(ItemChanges)
    }

    struct SectionChanges {
        let deletions: Set<Int>
        let insertions: Set<Int>
    }

    struct ItemChanges {
        let deletions: Set<Int>
        let insertions: Set<Int>
        let modifications: Set<Int>
        let section: Int
    }

    lazy var collectionView = UCollectionView(layout)
        .register(UCollectionDynamicCell.self)
        .edgesToSuperview()
        .dataSource(self)
        .delegate(self)
        .background(backgroundColor ?? .clear)

    var sections: [Section] = [] {
        didSet { self.updateRegistration() }
    }

    var scrollPosition: State<CGPoint>?
    var changesPool = 0
    var isChanging = false

    let layout: UICollectionViewLayout
    let items: [USectionItemable]

    public init (
        _ layout: UICollectionViewLayout = UCollectionView.defaultLayout,
        @CollectionBuilder<USection> block: () -> [USectionItemable]
    ) {
        self.layout = layout
        self.items = block()
        super.init(frame: .zero)
        self.items.forEach { self.process($0) }
        self.reloadData()
    }

    public init (
        _ layout: UICollectionViewLayout = UCollectionView.defaultLayout,
        @CollectionBuilder<USectionBodyItemable> block: () -> [USectionBodyItemable]
    ) {
        self.layout = layout
        self.items = [USection(identifier: 0, body: block())]
        super.init(frame: .zero)
        self.items.forEach { self.process($0) }
        self.reloadData()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func buildView() {
        super.buildView()
        body {
            collectionView
        }
    }

    // MARK: - Handlers

    var _willDisplay: ((IndexPath) -> Void)?

    public func willDisplay(_ handler: @escaping (IndexPath) -> Void) -> Self {
        self._willDisplay = handler
        return self
    }

    var _didSelectItemAt: ((IndexPath) -> Void)?

    public func didSelectItemAt(_ handler: @escaping (IndexPath) -> Void) -> Self {
        self._didSelectItemAt = handler
        return self
    }

    var _shouldHighlightItemAt: ((IndexPath) -> Bool)?

    public func shouldHighlightItemAt(_ handler: @escaping (IndexPath) -> Bool) -> Self {
        self._shouldHighlightItemAt = handler
        return self
    }
}

extension UCollection {
    func process(_ section: USectionItemable) {
        switch section.sectionItem {
        case let .single(section):
            section.body.forEach { self.process($0) }
        case let .forEach(fr):
            fr.allItems().forEach { self.process($0) }
            fr.subscribeToChanges { [weak self] in self?.reloadData()  }
        }
    }

    func process(_ item: USectionBodyItemable) {
        switch item.sectionBodyItem {
        case let .forEach(fr):
            fr.subscribeToChanges { [weak self] in self?.reloadData() }
        default:
            break
        }
    }

    func reloadData() {
        if self.isChanging {
            self.changesPool += 1
            return
        }

        self.isChanging = true

        let newSections = self.items
            .map { self.unwrapSections($0) }
            .flatMap { $0 }
            .map { Section($0) }

        if self.sections.isEmpty {
            self.sections = newSections
            self.collectionView.reloadData()
            self.isChanging = false
            return
        }

        var changesets: [Changeset] = []
        let sectionsDiff = self.sections.difference(newSections)

        changesets.append(.section(.init(
            deletions: Set(sectionsDiff.removed.compactMap { $0.index }),
            insertions: Set(sectionsDiff.inserted.compactMap { $0.index })
        )))

        sectionsDiff.modified.compactMap { $0.index }.forEach { section in
            let oldItems = self.sections[section].items.map { $0.identifier }
            let newItems = newSections[section].items.map { $0.identifier }
            let itemsDiff = oldItems.difference(newItems)
            changesets.append(.items(.init(
                deletions: Set(itemsDiff.removed.compactMap { $0.index }),
                insertions: Set(itemsDiff.inserted.compactMap { $0.index }),
                modifications: Set(itemsDiff.modified.compactMap { $0.index }),
                section: section
            )))
        }

        self.collectionView.performBatchUpdates({
            self.sections = newSections
            changesets.forEach {
                switch $0 {
                case let .section(changes):
                    self.collectionView.deleteSections(IndexSet(changes.deletions))
                    self.collectionView.insertSections(IndexSet(changes.deletions))
                case let .items(changes):
                    self.collectionView.deleteItems(at: changes.deletions.map { IndexPath(item: $0, section: changes.section)})
                    self.collectionView.insertItems(at: changes.insertions.map { IndexPath(item: $0, section: changes.section) })
                    self.collectionView.reloadItems(at: changes.modifications.map { IndexPath(item: $0, section: changes.section) })
                }
            }
        }, completion: { _ in
            self.isChanging = false
            if self.changesPool > 0 {
                self.changesPool -= 1
                self.reloadData()
            }
        })
    }

    func updateRegistration() {
        self.sections.forEach {
            _ = $0.header.map { self.collectionView.register($0.viewClass, UICollectionView.elementKindSectionHeader) }
            $0.items.forEach { self.collectionView.register($0.cellClass) }
            _ = $0.footer.map { self.collectionView.register($0.viewClass, UICollectionView.elementKindSectionFooter) }
        }
    }

    func unwrapSections(_ item: USectionItemable) -> [USection] {
        switch item.sectionItem {
        case let .single(section): return [section]
        case let .forEach(fr): return fr.allItems().map { self.unwrapSections($0) }.flatMap { $0 }
        }
    }
}

extension UCollection: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        self.sections.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.sections[section].items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        self.sections[indexPath.section].items[indexPath.item].generate(collectionView: collectionView, for: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        self.sections[indexPath.section].header?.generate(collectionView: collectionView, kind: kind, for: indexPath) ?? UICollectionReusableView()
    }
}

extension UCollection: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        self.sections[indexPath.section].items[indexPath.item].size(by: collectionView.frame.size)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        self.sections[section].header?.size(by: collectionView.frame.size) ?? .zero
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        self.sections[section].footer?.size(by: collectionView.frame.size) ?? .zero
    }
}

extension UCollection: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self._willDisplay?(indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self._didSelectItemAt?(indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        self._shouldHighlightItemAt?(indexPath) ?? true
    }
}

extension UCollection: UIScrollViewDelegate {
    @discardableResult
    public func contentOffset(_ position: CGPoint, animated: Bool = true) -> Self {
        self.collectionView.setContentOffset(position, animated: animated)
        return self
    }

    @discardableResult
    public func scrollPosition(_ binding: UIKitPlus.State<CGPoint>) -> Self {
        self.scrollPosition = binding
        return self
    }

    @discardableResult
    public func scrollPosition<V>(_ expressable: ExpressableState<V, CGPoint>) -> Self {
        self.scrollPosition = expressable.unwrap()
        return self
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollPosition?.wrappedValue = scrollView.contentOffset
    }
}

extension UCollection {
    @discardableResult
    public func keyboardDismissMode(_ mode: UIScrollView.KeyboardDismissMode) -> Self {
        self.collectionView.keyboardDismissMode = mode
        return self
    }

    @discardableResult
    public func refreshControl(_ refreshControl: UIRefreshControl) -> Self {
        self.collectionView.refreshControl(refreshControl)
        return self
    }

    @discardableResult
    public func alwaysBounceVertical(_ value: Bool = true) -> Self {
        self.collectionView.alwaysBounceVertical = value
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
}
#endif
