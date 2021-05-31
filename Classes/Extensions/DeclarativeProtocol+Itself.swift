extension DeclarativeProtocol {
    public func itself(_ itself: inout Self?) -> Self {
        itself = self
        return self
    }

    public func configure(_ closure: (Self) -> Void) -> Self {
        closure(self)
        return self
    }
}
