#if !os(macOS)
import UIKit
#if !os(tvOS)

@available(*, deprecated, renamed: "USlider")
public typealias USliderView = USlider
@available(*, deprecated, renamed: "USlider")
public typealias SliderView = USlider

open class USlider: UISlider, AnyDeclarativeProtocol, DeclarativeProtocolInternal {
    public var declarativeView: USlider { self }
    public lazy var properties = Properties<USlider>()
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
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        buildView()
        addTarget(self, action: #selector(_valueChanged), for: .valueChanged)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func buildView() {}
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutSubviews()
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        movedToSuperview()
    }

	open override func trackRect(forBounds bounds: CGRect) -> CGRect {
		guard let customHeight = self.customHeight else {
			return super.trackRect(forBounds: bounds)
		}
		return CGRect(origin: bounds.origin, size: CGSize(width: bounds.width, height: customHeight))
	}

	private var customHeight: CGFloat?

	@discardableResult
	public func customHeight(_ value: CGFloat) -> Self {
		self.customHeight = value
		return self
	}
    
    @discardableResult
    public func value(_ value: Float) -> Self {
        self.value = value
        return self
    }
    
    var bindValue: UISwift.State<Float>?
    
    @discardableResult
    public func value(_ binding: UISwift.State<Float>) -> Self {
        bindValue = binding
        binding.listen { [weak self] in self?.value($0) }
        return value(binding.wrappedValue)
    }
    
    @discardableResult
    public func minimumValue(_ value: Float) -> Self {
        minimumValue = value
        return self
    }
    
    @discardableResult
    public func minimumValue(_ binding: UISwift.State<Float>) -> Self {
        binding.listen { [weak self] in self?.minimumValue($0) }
        return minimumValue(binding.wrappedValue)
    }
    
    @discardableResult
    public func maximumValue(_ value: Float) -> Self {
        maximumValue = value
        return self
    }
    
    @discardableResult
    public func maximumValue(_ binding: UISwift.State<Float>) -> Self {
        binding.listen { [weak self] in self?.maximumValue($0) }
        return maximumValue(binding.wrappedValue)
    }
    
    @discardableResult
    public func minimumValueImage(_ value: UIImage?) -> Self {
        minimumValueImage = value
        return self
    }
    
    @discardableResult
    public func minimumValueImage(_ binding: UISwift.State<UIImage?>) -> Self {
        binding.listen { [weak self] in self?.minimumValueImage($0) }
        return minimumValueImage(binding.wrappedValue)
    }
    
    @discardableResult
    public func maximumValueImage(_ value: UIImage?) -> Self {
        maximumValueImage = value
        return self
    }
    
    @discardableResult
    public func maximumValueImage(_ binding: UISwift.State<UIImage?>) -> Self {
        binding.listen { [weak self] in self?.maximumValueImage($0) }
        return maximumValueImage(binding.wrappedValue)
    }
    
    @discardableResult
    public func isContinuous(_ value: Bool = true) -> Self {
        isContinuous = value
        return self
    }
    
    @discardableResult
    public func isContinuous(_ binding: UISwift.State<Bool>) -> Self {
        binding.listen { [weak self] in self?.isContinuous($0) }
        return isContinuous(binding.wrappedValue)
    }
    
    @discardableResult
    public func minimumTrackTintColor(_ value: UIColor?) -> Self {
        minimumTrackTintColor = value
        return self
    }
    
    @discardableResult
    public func minimumTrackTintColor(_ value: Int?) -> Self {
        minimumTrackTintColor = value?.color
        return self
    }
    
    @discardableResult
    public func minimumTrackTintColor(_ binding: UISwift.State<UIColor>) -> Self {
        binding.listen { [weak self] in self?.minimumTrackTintColor($0) }
        return minimumTrackTintColor(binding.wrappedValue)
    }
    
    @discardableResult
    public func minimumTrackTintColor(_ binding: UISwift.State<Int>) -> Self {
        binding.listen { [weak self] in self?.minimumTrackTintColor($0) }
        return minimumTrackTintColor(binding.wrappedValue)
    }
    
    @discardableResult
    public func maximumTrackTintColor(_ value: UIColor?) -> Self {
        maximumTrackTintColor = value
        return self
    }
    
    @discardableResult
    public func maximumTrackTintColor(_ value: Int?) -> Self {
        maximumTrackTintColor = value?.color
        return self
    }
    
    @discardableResult
    public func maximumTrackTintColor(_ binding: UISwift.State<UIColor>) -> Self {
        binding.listen { [weak self] in self?.maximumTrackTintColor($0) }
        return maximumTrackTintColor(binding.wrappedValue)
    }
    
    @discardableResult
    public func maximumTrackTintColor(_ binding: UISwift.State<Int>) -> Self {
        binding.listen { [weak self] in self?.maximumTrackTintColor($0) }
        return maximumTrackTintColor(binding.wrappedValue)
    }
    
    @discardableResult
    public func thumbTintColor(_ value: UIColor?) -> Self {
        thumbTintColor = value
        return self
    }
    
    @discardableResult
    public func thumbTintColor(_ value: Int?) -> Self {
        thumbTintColor = value?.color
        return self
    }
    
    @discardableResult
    public func thumbTintColor(_ binding: UISwift.State<UIColor>) -> Self {
        binding.listen { [weak self] in self?.thumbTintColor($0) }
        return thumbTintColor(binding.wrappedValue)
    }
    
    @discardableResult
    public func thumbTintColor(_ binding: UISwift.State<Int>) -> Self {
        binding.listen { [weak self] in self?.thumbTintColor($0) }
        return thumbTintColor(binding.wrappedValue)
    }
    
    @discardableResult
    public func tintColor(_ value: UIColor?) -> Self {
        tintColor = value
        return self
    }
    
    @discardableResult
    public func tintColor(_ value: Int?) -> Self {
        tintColor = value?.color
        return self
    }
    
    @discardableResult
    public func tintColor(_ binding: UISwift.State<UIColor>) -> Self {
        binding.listen { [weak self] in self?.tintColor($0) }
        return tintColor(binding.wrappedValue)
    }
    
    @discardableResult
    public func tintColor(_ binding: UISwift.State<Int>) -> Self {
        binding.listen { [weak self] in self?.tintColor($0) }
        return tintColor(binding.wrappedValue)
    }
    
    @discardableResult
    public func thumbImage(_ value: UIImage?, for state: UIControl.State = .normal) -> Self {
        setThumbImage(value, for: state)
        return self
    }
    
    @discardableResult
    public func thumbImage(_ binding: UISwift.State<UIImage?>) -> Self {
        binding.listen { [weak self] in self?.thumbImage($0) }
        return thumbImage(binding.wrappedValue)
    }
    
    var step: Float?
    
    @discardableResult
    public func step(_ value: Float) -> Self {
        step = value
        return self
    }
    
    // MARK: Value changed
    
    var _previousSteppedValue: Float?
    
    @objc
    private func _valueChanged() {
        if let step = step {
            let roundedValue = round(value / step) * step
            value = roundedValue
            if value != _previousSteppedValue {
                _onChange?(value)
                bindValue?.wrappedValue = value
            }
            _previousSteppedValue = value
        } else {
            _onChange?(value)
            bindValue?.wrappedValue = value
        }
    }
    
    public typealias OnChange = (Float) -> Void
    
    private var _onChange: OnChange?
    
    @discardableResult
    public func onChange(_ value: @escaping OnChange) -> Self {
        _onChange = value
        return self
    }
}
#endif
#endif
