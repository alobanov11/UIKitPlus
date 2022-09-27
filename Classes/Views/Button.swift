#if !os(macOS)
import UIKit

open class UButton: UIButton, AnyDeclarativeProtocol, DeclarativeProtocolInternal {
    public var declarativeView: UButton { self }
    public lazy var properties = Properties<UButton>()
    lazy var _properties = PropertiesInternal()
    
    @UISwift.State public var height: CGFloat = 0
    @UISwift.State public var width: CGFloat = 0
    @UISwift.State public var top: CGFloat = 0
    @UISwift.State public var leading: CGFloat = 0
    @UISwift.State public var left: CGFloat = 0
    @UISwift.State public var trailing: CGFloat = 0
    @UISwift.State public var right: CGFloat = 0
    @UISwift.State public var bottom: CGFloat = 0
    @UISwift.State public var centerX: CGFloat = 0
    @UISwift.State public var centerY: CGFloat = 0
    
    var __height: UISwift.State<CGFloat> { $height }
    var __width: UISwift.State<CGFloat> { $width }
    var __top: UISwift.State<CGFloat> { $top }
    var __leading: UISwift.State<CGFloat> { $leading }
    var __left: UISwift.State<CGFloat> { $left }
    var __trailing: UISwift.State<CGFloat> { $trailing }
    var __right: UISwift.State<CGFloat> { $right }
    var __bottom: UISwift.State<CGFloat> { $bottom }
    var __centerX: UISwift.State<CGFloat> { $centerX }
    var __centerY: UISwift.State<CGFloat> { $centerY }
    
    // MARK: States
    
    var titleNormal: UISwift.State<NSAttributedString>?
    var titleHighlighted: UISwift.State<NSAttributedString>?
    var titleDisabled: UISwift.State<NSAttributedString>?
    var titleSelected: UISwift.State<NSAttributedString>?
    var titleFocused: UISwift.State<NSAttributedString>?
    var titleApplication: UISwift.State<NSAttributedString>?
    var titleReserved: UISwift.State<NSAttributedString>?
    
    private var titleChangeTransition: UIView.AnimationOptions?
    
    open override func setTitle(_ title: String?, for state: UIControl.State) {
        guard let transition = titleChangeTransition else {
            super.setTitle(title, for: state)
            return
        }
        UIView.transition(with: self, duration: 0.25, options: transition, animations: {
            super.setTitle(title, for: state)
        }, completion: nil)
    }
    
    open override func setAttributedTitle(_ title: NSAttributedString?, for state: UIControl.State) {
        guard let transition = titleChangeTransition else {
            super.setAttributedTitle(title, for: state)
            return
        }
        UIView.transition(with: self, duration: 0.25, options: transition, animations: {
            super.setAttributedTitle(title, for: state)
        }, completion: nil)
    }

	open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		if self.bounds.width > 44 {
			return super.point(inside: point, with: event)
		}
		return self.bounds.insetBy(dx: -10, dy: -10).contains(point)
	}
    
    @discardableResult
    public func titleChangeTransition(_ value: UIView.AnimationOptions) -> Self {
        titleChangeTransition = value
        return self
    }
    
    // MARK: Initialization
    
    public convenience init (_ string: AnyString...) {
        self.init(type: .custom)
        _setup()
        title(string)
    }
    
    public convenience init (_ strings: [AnyString]) {
        self.init(type: .custom)
        _setup()
        title(strings)
    }
    
    public convenience init (_ localized: LocalizedString...) {
        self.init(type: .custom)
        _setup()
        title(localized)
    }
    
    public convenience init (_ localized: [LocalizedString]) {
        self.init(type: .custom)
        _setup()
        title(localized)
    }
    
    public convenience init<A: AnyString>(_ state: UISwift.State<A>) {
        self.init(type: .custom)
        _setup()
        title(state)
    }
    
    public convenience init (@AnyStringBuilder stateString: @escaping AnyStringBuilder.Handler) {
        self.init(type: .custom)
        _setup()
        title(stateString: stateString)
    }

	public convenience init(_ view: () -> UIView) {
		self.init(type: .custom)
		_setup()
		body {
			UWrapperView(view())
				.userInteraction(false)
				.edgesToSuperview()
		}
	}
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func _setup() {
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutSubviews()
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        movedToSuperview()
    }

	open override var isEnabled: Bool {
		didSet {
			alpha = isEnabled ? 1.0 : disabledAlpha ?? 1.0
		}
	}

	var disabledAlpha: CGFloat?

	@discardableResult
	public func disabledAlpha(_ value: CGFloat) -> Self {
		disabledAlpha = value
		return self
	}
    
    open override var isHighlighted: Bool {
        didSet {
			alpha = isHighlighted ? highlightedAlpha ?? 0.8 : 1.0
            if originalBackground == nil {
                originalBackground = backgroundColor
            }
            if isHighlighted {
                backgroundColor = backgroundHighlighted ?? backgroundColor
            } else {
                backgroundColor = originalBackground ?? backgroundColor
            }
        }
    }

	var highlightedAlpha: CGFloat?

	@discardableResult
	public func highlightedAlpha(_ value: CGFloat) -> Self {
		highlightedAlpha = value
		return self
	}
    
    // MARK: Background Highlighted
    
    var originalBackground: UIColor?
    var backgroundHighlighted: UIColor?
    
    @discardableResult
    public func backgroundHighlighted(_ color: UIColor, _ state: UIControl.State = .normal) -> Self {
        backgroundHighlighted = color
        return self
    }
    
    @discardableResult
    public func backgroundHighlighted(_ number: Int, _ state: UIControl.State = .normal) -> Self {
        backgroundHighlighted(number.color)
    }
    
    // MARK: Title
    
    @discardableResult
    public func title(_ value: LocalizedString..., for state: UIControl.State = .normal) -> Self {
        title(value, state)
    }
    
    @discardableResult
    public func title(_ value: [LocalizedString], _ state: UIControl.State = .normal) -> Self {
        setAttributedTitle(.init(string: String(value)), for: state)
        return self
    }
    
    @discardableResult
    public func title(_ value: AnyString..., for state: UIControl.State = .normal) -> Self {
        title(value, state)
    }
    
    @discardableResult
    public func title(_ value: [AnyString], _ state: UIControl.State = .normal) -> Self {
        setAttributedTitle(value.attributedString, for: state)
        return self
    }
    
    @discardableResult
    public func title<A: AnyString>(_ bind: UISwift.State<A>, _ state: UIControl.State = .normal) -> Self {
        setAttributedTitle(bind.wrappedValue.attributedString, for: state)
        let st: UISwift.State<NSAttributedString>
        switch state {
        case .application:
            st = titleApplication ?? .init(wrappedValue: bind.wrappedValue.attributedString)
        case .disabled:
            st = titleDisabled ?? .init(wrappedValue: bind.wrappedValue.attributedString)
        case .focused:
            st = titleFocused ?? .init(wrappedValue: bind.wrappedValue.attributedString)
        case .highlighted:
            st = titleHighlighted ?? .init(wrappedValue: bind.wrappedValue.attributedString)
        case .normal:
            st = titleNormal ?? .init(wrappedValue: bind.wrappedValue.attributedString)
        case .reserved:
            st = titleReserved ?? .init(wrappedValue: bind.wrappedValue.attributedString)
        case .selected:
            st = titleSelected ?? .init(wrappedValue: bind.wrappedValue.attributedString)
        default:
            st = .init(wrappedValue: bind.wrappedValue.attributedString)
        }
        bind.listen { [weak self] new in
            st.wrappedValue = new.attributedString
            self?.setAttributedTitle(new.attributedString, for: state)
        }
        return self
    }
    
    @discardableResult
    public func title(@AnyStringBuilder stateString: @escaping AnyStringBuilder.Handler) -> Self {
        title(stateString())
    }
    
    // MARK: Title Color
    
    @discardableResult
    public func color(_ color: UIColor, _ state: UIControl.State = .normal) -> Self {
        setTitleColor(color, for: state)
        return self
    }
    
    @discardableResult
    public func color(_ number: Int, _ state: UIControl.State = .normal) -> Self {
        color(number.color, state)
    }
    
    @discardableResult
    public func color(_ binding: UISwift.State<UIColor>, _ state: UIControl.State = .normal) -> Self {
        binding.listen { [weak self] in self?.color($0, state) }
        return color(binding.wrappedValue, state)
    }
    
    @discardableResult
    public func color(_ binding: UISwift.State<Int>, _ state: UIControl.State = .normal) -> Self {
        binding.listen { [weak self] in self?.color($0, state) }
        return color(binding.wrappedValue, state)
    }
    
    // MARK: Image
    
    @discardableResult
    public func image(_ image: UIImage?, _ state: UIControl.State = .normal) -> Self {
        setImage(image, for: state)
        return self
    }
    
    @discardableResult
    public func image(_ imageName: String, _ state: UIControl.State = .normal) -> Self {
        image(UIImage(named: imageName), state)
    }
    
    @discardableResult
    public func image(_ binding: UISwift.State<UIImage>, _ state: UIControl.State = .normal) -> Self {
        binding.listen { [weak self] in self?.image($0, state) }
        return image(binding.wrappedValue, state)
    }

	// MARK: Background Image
    
    @discardableResult
    public func backgroundImage(_ image: UIImage?, _ state: UIControl.State = .normal) -> Self {
        setBackgroundImage(image, for: state)
        return self
    }
    
    @discardableResult
    public func backgroundImage(_ imageName: String, _ state: UIControl.State = .normal) -> Self {
        backgroundImage(UIImage(named: imageName), state)
    }
    
    @discardableResult
    public func backgroundImage(_ binding: UISwift.State<UIImage>, _ state: UIControl.State = .normal) -> Self {
        binding.listen { [weak self] in self?.image($0, state) }
        return backgroundImage(binding.wrappedValue, state)
    }
    
    @discardableResult
    public func lineBreakMode(_ mode: NSLineBreakMode) -> Self {
        titleLabel?.lineBreakMode = mode
        return self
    }
    
    @discardableResult
    public func alignment(_ alignment: NSTextAlignment) -> Self {
        titleLabel?.textAlignment = alignment
        return self
    }
    
    // MARK: Mode
    
    @discardableResult
    public func mode(_ mode: UIView.ContentMode) -> Self {
        contentMode = mode
        return self
    }
    
    // MARK: Scale Factor
    
    @discardableResult
    public func minimumScaleFactor(_ value: CGFloat) -> Self {
        titleLabel?.minimumScaleFactor = value
        return self
    }
    
    // MARK: Insets
    
    @discardableResult
    public func contentInsets(_ insets: UIEdgeInsets) -> Self {
        contentEdgeInsets = insets
        return self
    }
    
    @discardableResult
    public func contentInsets(top: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0, bottom: CGFloat = 0) -> Self {
        contentInsets(.init(top: top, left: left, bottom: bottom, right: right))
    }
    
    @discardableResult
    public func titleInsets(_ insets: UIEdgeInsets) -> Self {
        titleEdgeInsets = insets
        return self
    }
    
    @discardableResult
    public func titleInsets(top: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0, bottom: CGFloat = 0) -> Self {
        titleInsets(.init(top: top, left: left, bottom: bottom, right: right))
    }
    
    @discardableResult
    public func imageInsets(_ insets: UIEdgeInsets) -> Self {
        imageEdgeInsets = insets
        return self
    }
    
    @discardableResult
    public func imageInsets(top: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0, bottom: CGFloat = 0) -> Self {
        imageInsets(.init(top: top, left: left, bottom: bottom, right: right))
    }
}

extension UButton: _Fontable {
    func _setFont(_ v: UIFont?) {
        titleLabel?.font = v
    }
}

extension UButton: _Enableable {
    func _setEnabled(_ v: Bool) {
        isEnabled = v
    }
}
#endif
