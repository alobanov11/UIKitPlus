#if !os(macOS)
import UIKit
#if !os(tvOS)

open class UDatePicker: UIDatePicker, AnyDeclarativeProtocol, DeclarativeProtocolInternal {
    public var declarativeView: UDatePicker { self }
    public lazy var properties = Properties<UDatePicker>()
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
        addTarget(self, action: #selector(changed), for: .valueChanged)
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
    
    // MARK: TextColor
    
    @discardableResult
    public func textColor(_ color: UIColor) -> Self {
        setValue(color, forKey: "textColor")
        return self
    }
    
    @discardableResult
    public func textColor(_ hex: Int) -> Self {
        textColor(hex.color)
    }
    
    @discardableResult
    public func textColor(_ binding: UISwift.State<UIColor>) -> Self {
        binding.listen { [weak self] in self?.textColor($0) }
        return textColor(binding.wrappedValue)
    }
    
    @discardableResult
    public func textColor(_ binding: UISwift.State<Int>) -> Self {
        binding.listen { [weak self] in self?.textColor($0) }
        return textColor(binding.wrappedValue)
    }
    
    // MARK: Mode
    
    @discardableResult
    public func mode(_ value: UIDatePicker.Mode) -> Self {
        datePickerMode = value
        return self
    }
    
    @discardableResult
    public func mode(_ binding: UISwift.State<UIDatePicker.Mode>) -> Self {
        binding.listen { [weak self] in self?.mode($0) }
        return mode(binding.wrappedValue)
    }
    
    // MARK: Locale
    
    @discardableResult
    public func locale(_ value: Locale) -> Self {
        locale = value
        return self
    }
    
    @discardableResult
    public func locale(_ binding: UISwift.State<Locale>) -> Self {
        binding.listen { [weak self] in self?.locale($0) }
        return locale(binding.wrappedValue)
    }
    
    // MARK: Calendar
    
    @discardableResult
    public func calendar(_ value: Calendar) -> Self {
        calendar = value
        return self
    }
    
    @discardableResult
    public func calendar(_ binding: UISwift.State<Calendar>) -> Self {
        binding.listen { [weak self] in self?.calendar($0) }
        return calendar(binding.wrappedValue)
    }
    
    // MARK: TimeZone
    
    @discardableResult
    public func timeZone(_ value: TimeZone) -> Self {
        timeZone = value
        return self
    }
    
    @discardableResult
    public func timeZone(_ binding: UISwift.State<TimeZone>) -> Self {
        binding.listen { [weak self] in self?.timeZone($0) }
        return timeZone(binding.wrappedValue)
    }
    
    // MARK: Date
    
    @discardableResult
    public func date(_ value: Date, animated: Bool = false) -> Self {
        setDate(value, animated: animated)
        return self
    }
    
    var dateBinding: UISwift.State<Date>?
    
    @discardableResult
    public func date(_ binding: UISwift.State<Date>, animated: Bool = false) -> Self {
        dateBinding = binding
        binding.listen { [weak self] in self?.date($0, animated: animated) }
        return date(binding.wrappedValue)
    }
    
    // MARK: Minimum Date
    
    @discardableResult
    public func minimumDate(_ value: Date) -> Self {
        minimumDate = value
        return self
    }
    
    @discardableResult
    public func minimumDate(_ binding: UISwift.State<Date>) -> Self {
        binding.listen { [weak self] in self?.minimumDate($0) }
        return minimumDate(binding.wrappedValue)
    }
    
    // MARK: Maximum Date
    
    @discardableResult
    public func maximumDate(_ value: Date) -> Self {
        maximumDate = value
        return self
    }
    
    @discardableResult
    public func maximumDate(_ binding: UISwift.State<Date>) -> Self {
        binding.listen { [weak self] in self?.maximumDate($0) }
        return maximumDate(binding.wrappedValue)
    }
    
    // MARK: Countdown Duration
    
    @discardableResult
    public func countDownDuration(_ value: TimeInterval) -> Self {
        countDownDuration = value
        return self
    }
    
    @discardableResult
    public func countDownDuration(_ binding: UISwift.State<TimeInterval>) -> Self {
        binding.listen { [weak self] in self?.countDownDuration($0) }
        return countDownDuration(binding.wrappedValue)
    }
    
    // MARK: Minute Interval
    
    @discardableResult
    public func minuteInterval(_ value: Int) -> Self {
        minuteInterval = value
        return self
    }
    
    @discardableResult
    public func minuteInterval(_ binding: UISwift.State<Int>) -> Self {
        binding.listen { [weak self] in self?.minuteInterval($0) }
        return minuteInterval(binding.wrappedValue)
    }
    
    // MARK: Handler
    
    private var _changed: (Date) -> Void = { _ in }
    
    @objc
    private func changed() {
        dateBinding?.wrappedValue = date
        _changed(date)
    }
    
    @discardableResult
    public func onChange(_ closure: @escaping (Date) -> Void) -> Self {
        _changed = closure
        return self
    }
}
#endif
#endif
