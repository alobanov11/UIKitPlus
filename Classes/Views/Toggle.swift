#if !os(macOS)
import UIKit
#if !os(tvOS)

open class UToggle: UISwitch, AnyDeclarativeProtocol, DeclarativeProtocolInternal {
    public var declarativeView: UToggle { self }
    public lazy var properties = Properties<UToggle>()
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
    
    var binding: UISwift.State<Bool>?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public init(_ state: UISwift.State<Bool>) {
        binding = state
        super.init(frame: .zero)
        setup()
        isOn = state.wrappedValue
        binding?.listen { [weak self] _, new in
            self?.setOn(new, animated: true)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        addTarget(self, action: #selector(changed), for: .valueChanged)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutSubviews()
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        movedToSuperview()
    }
    
    // MARK: Handler
    
    private var _changed: (Bool) -> Void = { _ in }
    
    @objc
    private func changed() {
        binding?.wrappedValue = isOn
        _changed(isOn)
    }
    
    @discardableResult
    public func onChange(_ closure: @escaping (Bool) -> Void) -> Self {
        _changed = closure
        return self
    }
    
    @discardableResult
    public func onTint(_ color: UIColor) -> Self {
        onTintColor = color
        return self
    }
    
    @discardableResult
    public func onTint(_ color: Int) -> Self {
        onTintColor = color.color
        return self
    }
    
    @discardableResult
    public func onTint(_ binding: UISwift.State<UIColor>) -> Self {
        binding.listen { [weak self] in self?.onTint($0) }
        return onTint(binding.wrappedValue)
    }
    
    @discardableResult
    public func onTint(_ binding: UISwift.State<Int>) -> Self {
        binding.listen { [weak self] in self?.onTint($0) }
        return onTint(binding.wrappedValue)
    }
    
    @discardableResult
    public func thumbTint(_ color: UIColor) -> Self {
        thumbTintColor = color
        return self
    }
    
    @discardableResult
    public func thumbTint(_ color: Int) -> Self {
        thumbTintColor = color.color
        return self
    }
    
    @discardableResult
    public func thumbTint(_ binding: UISwift.State<UIColor>) -> Self {
        binding.listen { [weak self] in self?.thumbTint($0) }
        return thumbTint(binding.wrappedValue)
    }
    
    @discardableResult
    public func thumbTint(_ binding: UISwift.State<Int>) -> Self {
        binding.listen { [weak self] in self?.thumbTint($0) }
        return thumbTint(binding.wrappedValue)
    }
    
    @discardableResult
    public func onImage(_ image: UIImage?) -> Self {
        onImage = image
        return self
    }
    
    @discardableResult
    public func onImage(_ binding: UISwift.State<UIImage?>) -> Self {
        binding.listen { [weak self] in self?.onImage($0) }
        return onImage(binding.wrappedValue)
    }
    
    @discardableResult
    public func offImage(_ image: UIImage?) -> Self {
        offImage = image
        return self
    }
    
    @discardableResult
    public func offImage(_ binding: UISwift.State<UIImage?>) -> Self {
        binding.listen { [weak self] in self?.offImage($0) }
        return offImage(binding.wrappedValue)
    }
}

extension UToggle: _Enableable {
    func _setEnabled(_ v: Bool) {
        isEnabled = v
    }
}
#endif
#endif
