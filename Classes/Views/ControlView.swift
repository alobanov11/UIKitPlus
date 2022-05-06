#if !os(macOS)
import UIKit

@available(*, deprecated, renamed: "UControlView")
public typealias ControlView = UControlView

open class UControlView: UIControl, AnyDeclarativeProtocol, DeclarativeProtocolInternal {
    public var declarativeView: ControlView { self }
    public lazy var properties = Properties<ControlView>()
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
}
#endif
