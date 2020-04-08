import UIKit

extension DeclarativeProtocol {
    @discardableResult
    public func onPanGesture(minTouches: Int? = nil, maxTouches: Int? = nil, _ action: @escaping (PanGestureRecognizer) -> Void) -> Self {
        let recognizer = PanGestureRecognizer(minTouches: minTouches, maxTouches: maxTouches)
        declarativeView.addGestureRecognizer(recognizer.trackState { _ in
            action(recognizer)
        })
        return self
    }
    
    @discardableResult
    public func onPanGesture(minTouches: Int? = nil, maxTouches: Int? = nil, _ action: @escaping (Self, PanGestureRecognizer) -> Void) -> Self {
        let recognizer = PanGestureRecognizer(minTouches: minTouches, maxTouches: maxTouches)
        declarativeView.addGestureRecognizer(recognizer.trackState { _ in
            action(self, recognizer)
        })
        return self
    }
    
    @discardableResult
    public func onPanGesture(_ state: State<UIGestureRecognizer.State>, minTouches: Int? = nil, maxTouches: Int? = nil) -> Self {
        declarativeView.addGestureRecognizer(PanGestureRecognizer(minTouches: minTouches, maxTouches: maxTouches).trackState {
            state.wrappedValue = $0
        })
        return self
    }

    @discardableResult
    public func onPanGesture<V>(_ expressable: ExpressableState<V, UIGestureRecognizer.State>, minTouches: Int? = nil, maxTouches: Int? = nil) -> Self {
        onPanGesture(expressable.unwrap(), minTouches: minTouches, maxTouches: maxTouches)
    }
}