public class ExpressableState<S, Result> where S: Stateable {
	unowned let state: S

	private let _expression: (S.Value) -> Result
    
    init (_ state: S, _ expression: @escaping (S.Value) -> Result) {
        self.state = state
		self._expression = expression
    }

	func value() -> Result {
		self._expression(self.state.wrappedValue)
	}
    
    public func unwrap() -> State<Result> {
        let state = State(wrappedValue: self.value())
		let expression = self._expression
        self.state.listen { newValue in
            state.wrappedValue = expression(newValue)
        }
        return state
    }
}

extension Stateable {
    public func map<Result>(_ expression: @escaping () -> Result) -> ExpressableState<Self, Result> {
        .init(self) { _ in
            expression()
        }
    }
    
    public func map<Result>(_ expression: @escaping (Value) -> Result) -> ExpressableState<Self, Result> {
        .init(self, expression)
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
