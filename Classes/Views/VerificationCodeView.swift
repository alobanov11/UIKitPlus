#if !os(macOS)
import UIKit

@available(*, deprecated, renamed: "UVerificationCodeView")
public typealias VerificationCodeView = UVerificationCodeView

open class UVerificationCodeView: UIView, AnyDeclarativeProtocol, DeclarativeProtocolInternal {
    public var declarativeView: UVerificationCodeView { self }
    public lazy var properties = Properties<UVerificationCodeView>()
    lazy var _properties = PropertiesInternal()
    
    @State public var height: CGFloat = 0
    @State public var width: CGFloat = 0
    @State public var top: CGFloat = 0
    @State public var leading: CGFloat = 0
    @State public var left: CGFloat = 0
    @State public var trailing: CGFloat = 0
    @State public var right: CGFloat = 0
    @State public var bottom: CGFloat = 0
    @State public var centerX: CGFloat = 0
    @State public var centerY: CGFloat = 0
    
    var __height: State<CGFloat> { _height }
    var __width: State<CGFloat> { _width }
    var __top: State<CGFloat> { _top }
    var __leading: State<CGFloat> { _leading }
    var __left: State<CGFloat> { _left }
    var __trailing: State<CGFloat> { _trailing }
    var __right: State<CGFloat> { _right }
    var __bottom: State<CGFloat> { _bottom }
    var __centerX: State<CGFloat> { _centerX }
    var __centerY: State<CGFloat> { _centerY }
    
    private let quantity: Int
    
    public typealias EnteredClosure = (String) -> Void
    private var enteredClosure: EnteredClosure  = { _ in }
    private var simpleEnteredClosure  = {}

    public init (_ quantity: Int = 4) {
        self.quantity = quantity
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }
    
    public override init(frame: CGRect) {
        quantity = 4
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutSubviews()
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        movedToSuperview()
    }
    
	lazy var hiddenTextField = UTextField()
		.edgesToSuperview(top: 0, leading: 0)
		.color(.clear)
		.alpha(0.05)
		.keyboard(.numberPad)
		.editingChanged { [weak self] in self?.edited($0) }
		.shouldChangeCharacters { [weak self] in
			self?.shouldChangeCharacters($0, range: $1, replacement: $2) ?? false
		}
    
    var digitViews: [UText] = []
    
    var isSecureField = false {
        didSet {
            edited(hiddenTextField)
        }
    }
    var secureSymbol = "∙" {
        didSet {
            edited(hiddenTextField)
        }
    }
    
    @State var widthOfDigitView: CGFloat = 24
    @State var spaceBetweenDigitViews: CGFloat = 10
    
    public var code: String {
		get { hiddenTextField.text ?? "" }
		set {
			hiddenTextField.text = newValue
			edited(hiddenTextField)
		}
    }
    
    @discardableResult
    public func secured(_ value: Bool = true) -> Self {
        isSecureField = value
        return self
    }
    
    @discardableResult
    public func secureSymbol(_ value: String) -> Self {
        secureSymbol = value
        return self
    }
    
    @discardableResult
    public func digitWidth(_ value: CGFloat) -> Self {
        widthOfDigitView = value
        return self
    }
    
    @discardableResult
    public func digitsMargin(_ margin: CGFloat) -> Self {
        spaceBetweenDigitViews = margin
        return self
    }

	@discardableResult
    public func digitColor(_ color: UIColor) -> Self {
		digitViews.forEach { $0.color(color) }
        return self
    }
    
    @discardableResult
    public func digitColor(_ number: Int) -> Self {
        digitColor(number.color)
    }

    @discardableResult
    public func digitBackground(_ color: UIColor) -> Self {
		digitViews.forEach { $0.background(color) }
        return self
    }
    
    @discardableResult
    public func digitBackground(_ number: Int) -> Self {
        digitBackground(number.color)
    }
    
    @discardableResult
    public func digitCorners(_ radius: CGFloat, _ corners: UIRectCorner...) -> Self {
        digitViews.forEach { $0.corners(radius, corners) }
        return self
    }
    
    @discardableResult
    public func digitBorder(_ width: CGFloat, _ color: UIColor) -> Self {
        digitViews.forEach { $0.border(width, color) }
        return self
    }
    
    @discardableResult
    public func digitBorder(_ width: CGFloat, _ number: Int) -> Self {
        digitBorder(width, number.color)
        return self
    }
    
    @discardableResult
    public func digitBorder(_ side: Borders.Side, _ width: CGFloat, _ color: UIColor) -> Self {
        digitViews.forEach { $0.border(side, width, color) }
        return self
    }
    
    @discardableResult
    public func digitBorder(_ side: Borders.Side, _ width: CGFloat, _ number: Int) -> Self {
        digitBorder(side, width, number.color)
        return self
    }
    
    @discardableResult
    public func removeDigitBorder(_ side: Borders.Side) -> Self {
        digitViews.forEach { $0.removeBorder(side) }
        return self
    }
    
    @discardableResult
    public func digitShadow(_ colorNumber: Int, opacity: Float = 1, x: CGFloat = 0, y: CGFloat = 0, radius: CGFloat = 10) -> Self {
        digitShadow(colorNumber.color, opacity: opacity, x: x, y: y, radius: radius)
    }
    
    @discardableResult
    public func digitShadow(_ color: UColor = .black, opacity: Float = 1, x: CGFloat = 0, y: CGFloat = 0, radius: CGFloat = 10) -> Self {
        digitViews.forEach { $0.shadow(color, opacity: opacity, x: x, y: y, radius: radius) }
        return self
    }
    
    func setupView() {
        digitViews = (0...quantity - 1).map { _ in
			UText()
				.alignment(.center)
				.background(.clear)
				.width($widthOfDigitView)
		}
        body {
            hiddenTextField.size(1, 30).content(.oneTimeCode)
            UHStack {
                digitViews
            }.spacing($spaceBetweenDigitViews).edgesToSuperview()
        }
        onTapGesture { self.becomeFirstResponder() }
    }
    
    open func edited(_ textField: UTextField) {
        let labels = digitViews
        for label in labels {
            guard let text = hiddenTextField.text else { continue }
            guard let index = labels.firstIndex(of: label) else { continue }
            let letters = text.map { String($0) }
            if letters.count >= index + 1 {
                label.text = isSecureField ? secureSymbol : String(letters[index])
                label.alpha = 1
            } else {
                label.text = ""
            }
        }
        if hiddenTextField.text?.count == digitViews.count {
            enteredClosure(hiddenTextField.text ?? "")
            simpleEnteredClosure()
        }
    }
    
    func shouldChangeCharacters(_ textField: UTextField, range: NSRange, replacement: String) -> Bool {
        guard !replacement.isEmpty else { return true }
        if textField.text?.count == digitViews.count {
            textField.text = replacement
            edited(textField)
            return false
        }
        return true
    }
    
    @discardableResult
    public func entered(_ closure: @escaping EnteredClosure) -> Self {
        enteredClosure = closure
        return self
    }
    
    @discardableResult
    public func entered(_ closure: @escaping () -> Void) -> Self {
        simpleEnteredClosure = closure
        return self
    }
    
    @discardableResult
    public func keyboardAppearance(_ appearance: UIKeyboardAppearance) -> Self {
        hiddenTextField.keyboardAppearance = appearance
        return self
    }
    
    @discardableResult
    open override func becomeFirstResponder() -> Bool {
        hiddenTextField.becomeFirstResponder()
    }
    
    public func cleanup() {
        hiddenTextField.cleanup()
    }

	@discardableResult
	public func keyboard(_ keyboard: UIKeyboardType) -> Self {
		hiddenTextField.keyboard(keyboard)
		return self
	}
}

extension VerificationCodeView: _Fontable {
    func _setFont(_ v: UIFont?) {
		digitViews.forEach { $0.font(v: v) }
    }
}#endif
