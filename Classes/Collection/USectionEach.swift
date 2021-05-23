//
//  Created by Антон Лобанов on 23.05.2021.
//

public protocol AnySectionEach {
    var count: Int { get }
    func allItems() -> [USectionItemable]
    func item(at index: Int) -> USectionItemable?
    func subscribeToChanges(_ handler: @escaping () -> Void)
}

public final class USectionEach<Item: Hashable> {
    public typealias BuildHandler = (Int, Item) -> USectionItemable

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

extension USectionEach: AnySectionEach {
    public var count: Int {
        self.items.wrappedValue.count
    }

    public func allItems() -> [USectionItemable] {
        self.items.wrappedValue.enumerated().map {
            self.block($0.offset, $0.element)
        }
    }

    public func item(at index: Int) -> USectionItemable? {
        guard index < self.items.wrappedValue.count else { return nil }
        return self.block(index, self.items.wrappedValue[index])
    }

    public func subscribeToChanges(_ handler: @escaping () -> Void) {
        self.items.removeAllListeners()
        self.items.listen { $0 != $1 ? handler() : () }
    }
}

extension USectionEach: USectionItemable {
    public var sectionItem: USectionItem { .forEach(self) }
}
