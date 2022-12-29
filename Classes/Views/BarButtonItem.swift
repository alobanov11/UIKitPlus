#if !os(macOS)
import UIKit

@available(*, deprecated, renamed: "UBarButtonItem")
public typealias BarButtonItem = UBarButtonItem

open class UBarButtonItem: UIBarButtonItem {
    public init(_ title: String?) {
        super.init()
        self.title = title
        setup()
    }

	public init(_ title: State<String>) {
		super.init()
		self.title = title.wrappedValue
		setup()
		title.listen { [weak self] in self?.title = $0 }
	}
    
    public init(_ localized: LocalizedString...) {
        super.init()
        self.title = String(localized)
        setup()
    }
    
    public init(_ localized: [LocalizedString]) {
        super.init()
        self.title = String(localized)
        setup()
    }
    
    public init(image: UIImage?) {
        super.init()
        self.image = image
        setup()
    }
    
    public init(_ image: State<UIImage>) {
        super.init()
        self.image = image.wrappedValue
        setup()
        image.listen { [weak self] in self?.image = $0 }
    }
    
    public init(image imageName: String) {
        super.init()
        self.image = UIImage(named: imageName)
        setup()
    }
    
    public init(_ customView: UIView) {
        super.init()
        self.customView = customView
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        target = self
        action = #selector(tapEvenWithbuttont(_:))
    }
    
    // MARK: TouchUpInside
    
    public typealias TapAction = ()->Void
    public typealias TapActionWithButton = (UBarButtonItem)->Void
    
    private var tapCallback: TapAction?
    private var tapWithButtonCallback: TapActionWithButton?
    
    @discardableResult
    public func tapAction(_ callback: @escaping TapAction) -> Self {
        tapCallback = callback
        return self
    }
    
    @discardableResult
    public func tapAction(_ callback: @escaping TapActionWithButton) -> Self {
        tapWithButtonCallback = callback
        return self
    }
    
    @objc private func tapEvenWithbuttont(_ button: UBarButtonItem) {
        tapCallback?()
        tapWithButtonCallback?(button)
    }
    
    @discardableResult
    public func style(_ style: UIBarButtonItem.Style) -> Self {
        self.style = style
        return self
    }
}

extension UBarButtonItem: _Tintable {
	var _tintState: State<UColor> {
		.init(wrappedValue: self.tintColor ?? .clear)
	}

	func _setTint(_ v: UColor?) {
		self.tintColor = v
	}
}

extension UBarButtonItem: _Enableable {
	func _setEnabled(_ v: Bool) {
		self.isEnabled = v
	}
}


#endif
