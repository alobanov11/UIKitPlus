import UIKit

public protocol Messageable: class {
    @discardableResult
    func message(_ text: String) -> Self
    
    @discardableResult
    func message(_ state: State<String>) -> Self
    
    @discardableResult
    func message<V>(_ expressable: ExpressableState<V, String>) -> Self
    
    @discardableResult
    func message(@StateStringBuilder stateString: @escaping StateStringBuilder.Handler) -> Self
}

protocol _Messageable: Messageable {
    func _setMessage(_ v: String?)
}

extension Titleable {
    @discardableResult
    public func message(_ text: String) -> Self {
        guard let s = self as? _Messageable else { return self }
        s._setMessage(text)
        return self
    }

    @discardableResult
    public func message(_ state: State<String>) -> Self {
        guard let s = self as? _Messageable else { return self }
        s._setMessage(state.wrappedValue)
        state.listen { s._setMessage($0) }
        return self
    }

    @discardableResult
    public func message<V>(_ expressable: ExpressableState<V, String>) -> Self {
        message(expressable.unwrap())
    }

    @discardableResult
    public func message(@StateStringBuilder stateString: @escaping StateStringBuilder.Handler) -> Self {
        message(stateString())
    }
}