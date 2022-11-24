extension DeclarativeProtocol {
    internal var _declarativeView: DeclarativeProtocolInternal { self as! DeclarativeProtocolInternal }

	@discardableResult
	public func translates(_ value: Bool = true) -> Self {
		self.declarativeView.translatesAutoresizingMaskIntoConstraints = value
		return self
	}

	@discardableResult
	public func transform(_ value: CGAffineTransform) -> Self {
		self.declarativeView.transform = value
		return self
	}
}
