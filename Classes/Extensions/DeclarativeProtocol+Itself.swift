extension DeclarativeProtocol {
	@discardableResult
    public func itself(_ itself: inout Self?) -> Self {
        itself = self
        return self
    }

	@discardableResult
    public func configure(_ closure: (Self) -> Void) -> Self {
        closure(self)
        return self
    }
}
