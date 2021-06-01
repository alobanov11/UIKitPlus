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

    init(_ items: [USectionItemable]) {
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

    init(_ items: [USectionBodyItemable]) {
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
    
    func generate(collectionView: UICollectionView, for indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(with: Cell.self, for: indexPath)
        self.build(cell)
        return cell
    }
}

public protocol UItemableDelegate {
    func willDisplay()
    func didSelect()
    func didDeselect()
}

public extension UItemableDelegate {
    func willDisplay() {}
    func didSelect() {}
    func didDeselect() {}
}

// MARK: - USection

public struct USection {
    let identifier: AnyHashable
    let body: [USectionBodyItemable]
}

extension USection {
    public init<T: Hashable>(_ identifier: T, @CollectionBuilder<USectionBodyItemable> block: () -> [USectionBodyItemable]) {
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
