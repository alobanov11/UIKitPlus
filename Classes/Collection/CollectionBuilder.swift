//
//  Created by Антон Лобанов on 23.05.2021.
//

@resultBuilder
enum CollectionBuilder<Element> {
    typealias Expression = Element
    typealias Component = [Element]

    static func buildExpression(_ expression: Expression) -> Component { [expression] }
    static func buildExpression(_ expression: Expression?) -> Component { expression.map { [$0] } ?? [] }
    static func buildBlock(_ children: Component...) -> Component { children.flatMap { $0 } }
    static func buildOptional(_ children: Component?) -> Component { children ?? [] }
    static func buildBlock(_ component: Component) -> Component { component }
    static func buildEither(first child: Component) -> Component { child }
    static func buildEither(second child: Component) -> Component { child }
}
