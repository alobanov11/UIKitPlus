extension Stateable {
	public func map<Result>(_ expression: @escaping (Value) -> Result) -> State<Result> {
		let state = State(wrappedValue: expression(self.wrappedValue))
		self.listen { state.wrappedValue = expression($0) }
		return state
	}
}

// MARK: Any States to Expressable

public protocol AnyState {
    func listen(_ listener: @escaping () -> Void)
}

public class AnyStates {
    private let _expression: () -> Void
    lazy var value: () -> Void = {
        self._expression()
    }
    
    @discardableResult
    init (_ states: [AnyState], expression: @escaping () -> Void) {
        _expression = expression
        states.forEach { $0.listen(expression) }
    }
}

extension Array where Element == AnyState {
    public func map<Result>(_ expression: @escaping () -> Result) -> State<Result> {
        let sss = State<Result>.init(wrappedValue: expression())
        AnyStates(self) {
            sss.wrappedValue = expression()
        }
        return sss
    }
}
