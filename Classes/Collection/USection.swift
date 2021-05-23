//
//  Created by Антон Лобанов on 23.05.2021.
//

import UIKit

public enum USectionItem {
    case single(USection)
    case forEach(AnySectionEach)
}

public protocol USectionItemable {
    var sectionItem: USectionItem { get }
}

// MARK: - USectionBodyItem

public enum USectionBodyItem {
    case supplementary(USupplementable)
    case item(UItemable)
    case forEach(AnyItemEach)
}

public protocol USectionBodyItemable {
    var identifier: AnyHashable { get }
    var sectionBodyItem: USectionBodyItem { get }
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

extension USupplementable where Self: USupplementableBuilder {
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

extension UItemable where Self: UItemableBuilder {
    var cellClass: Cellable.Type {
        Cell.self
    }

    func generate(collectionView: UICollectionView, for indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(with: Cell.self, for: indexPath)
        self.build(cell)
        return cell
    }
}

// MARK: - USection

public struct USection {
    let body: [USectionBodyItemable]
}

extension USection {
    public init(@CollectionBuilder<USectionBodyItemable> block: () -> [USectionBodyItemable]) {
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
        case let .forEach(fr): return fr.allItems().map { self.unwrapItems($0) }.flatMap { $0 }
        default: return []
        }
    }
}

extension USection: Hashable {
    public static func == (lhs: USection, rhs: USection) -> Bool {
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

extension USection: USectionItemable {
    public var sectionItem: USectionItem { .single(self) }
}
