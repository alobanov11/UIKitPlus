//
//  Created by Антон Лобанов on 23.05.2021.
//

import UIKit

public enum USectionItem {
    case single(USection)
    case map(AnySectionMap)
    case multiple([USectionItemable])
}

public protocol USectionItemable {
    var sectionItem: USectionItem { get }
}

public struct MultipleSectionItem: USectionItemable {
    public var sectionItem: USectionItem { .multiple(self.items) }
    public let items: [USectionItemable]

    public init(_ items: [USectionItemable]) {
        self.items = items
    }
}

extension Array: USectionItemable where Element == USection {
    public var sectionItem: USectionItem { .multiple(self) }
}

// MARK: - USectionBodyItem

public enum USectionBodyItem {
    case supplementary(USupplementable)
    case item(UItemable)
    case map(AnyItemMap)
    case multiple([USectionBodyItemable])
}

public protocol USectionBodyItemable {
    var identifier: AnyHashable { get }
    var sectionBodyItem: USectionBodyItem { get }
}

public struct MultipleSectionBodyItem: USectionBodyItemable {
    public var identifier: AnyHashable { self.items.map { $0.identifier } }
    public var sectionBodyItem: USectionBodyItem { .multiple(self.items) }
    public let items: [USectionBodyItemable]

    public init(_ items: [USectionBodyItemable]) {
        self.items = items
    }
}

// MARK: - USupplementable

public protocol USupplementable: USectionBodyItemable {
    var viewClass: Supplementable.Type { get }
    func generate(collectionView: UICollectionView, kind: String, for indexPath: IndexPath) -> UICollectionReusableView
    func size(by original: CGSize) -> CGSize
}

extension USupplementable {
    public var sectionBodyItem: USectionBodyItem { .supplementary(self) }
}

public protocol USupplementableBuilder {
    associatedtype View: UICollectionReusableView & Supplementable
    func build(_ view: View)
}

public extension USupplementable where Self: USupplementableBuilder {
    var viewClass: Supplementable.Type {
        View.self
    }

    func generate(collectionView: UICollectionView, kind: String, for indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(View.self, ofKind: kind, for: indexPath)
        self.build(view)
        return view
    }
}

// MARK: - UItemable

public final class UItemSizeCache {
	public static let shared = UItemSizeCache()

	private var sizes: [String: [AnyHashable: CGSize]] = [:]

	public func size<Cell: Cellable, Identifier: Hashable>(_ type: Cell.Type, identifier: Identifier) -> CGSize? {
		self.sizes[type.reuseIdentifier]?[identifier]
	}

	public func update<Cell: Cellable, Identifier: Hashable>(_ type: Cell.Type, identifier: Identifier, size: CGSize) {
		if self.sizes[type.reuseIdentifier] == nil {
			self.sizes[type.reuseIdentifier] = [identifier: size]
		}
		else {
			self.sizes[type.reuseIdentifier]?[identifier] = size
		}
	}

	public func clearAll() {
		self.sizes = [:]
	}

	public func clear<Cell: Cellable>(for type: Cell.Type) {
		self.sizes[type.reuseIdentifier] = [:]
	}
}

public protocol UItemable: USectionBodyItemable {
    var cellClass: Cellable.Type { get }

	func generate(collectionView: UICollectionView, for indexPath: IndexPath) -> UICollectionViewCell
    func size(by original: CGSize) -> CGSize
}

extension UItemable {
    public var sectionBodyItem: USectionBodyItem { .item(self) }
}

public protocol UItemableBuilder {
    associatedtype Cell: UICollectionViewCell & Cellable
    func build(_ cell: Cell)
}

public extension UItemable where Self: UItemableBuilder {
    var cellClass: Cellable.Type {
        Cell.self
    }

	func size(by original: CGSize) -> CGSize {
		self.systemLayoutSize(by: original, direction: original.height > original.width ? .vertical : .horizontal)
	}
    
    func generate(collectionView: UICollectionView, for indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(with: Cell.self, for: indexPath)
        self.build(cell)
        return cell
    }

	func systemLayoutSize(by original: CGSize, direction: UICollectionView.ScrollDirection) -> CGSize {
		if let cachedSize = UItemSizeCache.shared.size(Cell.self, identifier: self.identifier) {
			return cachedSize
		}
		let isDynamicHeight = (direction == .vertical)
		let width = isDynamicHeight ? original.width : .greatestFiniteMagnitude
		let height = isDynamicHeight ? .greatestFiniteMagnitude : original.height
		let cell = Cell(frame: .init(origin: .zero, size: .init(width: width, height: height)))
		self.build(cell)
		let size = cell.systemLayoutSizeFitting(
			.init(width: width, height: height),
			withHorizontalFittingPriority: isDynamicHeight ? .required : .fittingSizeLevel,
			verticalFittingPriority: isDynamicHeight ? .fittingSizeLevel : .required
		)
		UItemSizeCache.shared.update(Cell.self, identifier: self.identifier, size: size)
		return size
	}
}

public protocol UItemableDelegate {
    func willDisplay()
    func didSelect()
    func didDeselect()
    func didHighlight()
    func didUnhighlight()
}

public extension UItemableDelegate {
    func willDisplay() {}
    func didSelect() {}
    func didDeselect() {}
    func didHighlight() {}
    func didUnhighlight() {}
}

// MARK: - USection

public struct USection {
	public typealias Identifier = AnyHashable

    let identifier: Identifier
    let body: [USectionBodyItemable]
}

extension USection {
    public init(_ identifier: Identifier, @CollectionBuilder<USectionBodyItemable> block: () -> [USectionBodyItemable]) {
        self.identifier = identifier
        self.body = block()
    }
    
    var header: USupplementable? {
        guard case let .supplementary(item) = self.body.first?.sectionBodyItem else { return nil }
        return item
    }
    
    var footer: USupplementable? {
        guard case let .supplementary(item) = self.body.last?.sectionBodyItem else { return nil }
        return item
    }
    
    var items: [UItemable] {
        self.body
            .map { self.unwrapItems($0) }
            .flatMap { $0 }
    }
    
    private func unwrapItems(_ item: USectionBodyItemable) -> [UItemable] {
        switch item.sectionBodyItem {
        case let .item(item): return [item]
        case let .map(mp): return mp.allItems().map { self.unwrapItems($0) }.flatMap { $0 }
        case let .multiple(items): return items.map { self.unwrapItems($0) }.flatMap { $0 }
        default: return []
        }
    }
}

extension USection: USectionItemable {
    public var sectionItem: USectionItem { .single(self) }
}

// MARK: - Empty

public struct EmptySection: USectionItemable {
    public var sectionItem: USectionItem { .single(self.section) }
    private let section = USection(UUID().uuidString, block: {})

    public init() {}
}

public struct EmptyItem: USectionBodyItemable {
    public let identifier: AnyHashable = UUID().uuidString
    public var sectionBodyItem: USectionBodyItem { .multiple([]) }

    public init() {}
}


