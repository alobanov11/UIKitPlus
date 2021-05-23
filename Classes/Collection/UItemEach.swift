//
//  Created by Антон Лобанов on 23.05.2021.
//

public protocol AnyItemEach {
    var count: Int { get }
    func allItems() -> [USectionBodyItemable]
    func item(at index: Int) -> USectionBodyItemable?
    func subscribeToChanges(_ handler: @escaping () -> Void)
}

public final class UItemEach<Item: Hashable> {
    public typealias BuildHandler = (Int, Item) -> USectionBodyItemable

    let items: State<[Item]>
    let block: BuildHandler

    public init (_ items: [Item], block: @escaping BuildHandler) {
        self.items = State(wrappedValue: items)
        self.block = block
    }

    public init (_ items: State<[Item]>, block: @escaping BuildHandler) {
        self.items = items
        self.block = block
    }
}

extension UItemEach: AnyItemEach {
    public var count: Int {
        self.items.wrappedValue.count
    }

    public func allItems() -> [USectionBodyItemable] {
        self.items.wrappedValue.enumerated().map {
            self.block($0.offset, $0.element)
        }
    }

    public func item(at index: Int) -> USectionBodyItemable? {
        guard index < self.items.wrappedValue.count else { return nil }
        return self.block(index, self.items.wrappedValue[index])
    }

    public func subscribeToChanges(_ handler: @escaping () -> Void) {
        self.items.removeAllListeners()
        self.items.listen { $0 != $1 ? handler() : () }
    }
}

extension UItemEach: USectionBodyItemable {
    public var identifier: AnyHashable { self.items.wrappedValue }
    public var sectionBodyItem: USectionBodyItem { .forEach(self) }
}
