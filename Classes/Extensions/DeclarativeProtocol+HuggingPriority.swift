#if !os(macOS)
import UIKit

extension DeclarativeProtocol {
    @discardableResult
    public func huggingPriority(x value: UILayoutPriority) -> Self {
        declarativeView.setContentHuggingPriority(value, for: .horizontal)
        return self
    }
    
    @discardableResult
    public func huggingPriority(y value: UILayoutPriority) -> Self {
        declarativeView.setContentHuggingPriority(value, for: .vertical)
        return self
    }
    
    @discardableResult
    public func huggingPriority(x value: Float) -> Self {
        declarativeView.setContentHuggingPriority(.init(value), for: .horizontal)
        return self
    }
    
    @discardableResult
    public func huggingPriority(y value: Float) -> Self {
        declarativeView.setContentHuggingPriority(.init(value), for: .vertical)
        return self
    }

	@discardableResult
	public func huggingPriority(x: Float, y: Float) -> Self {
		self.huggingPriority(x: x)
		self.huggingPriority(y: y)
		return self
	}
}
#endif
