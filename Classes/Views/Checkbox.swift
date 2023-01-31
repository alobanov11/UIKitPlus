//
//  Created by Антон Лобанов on 31.01.2023.
//

import UIKit

public final class UCheckbox: UIControl, AnyDeclarativeProtocol, DeclarativeProtocolInternal {
	public var declarativeView: UCheckbox { self }
	public lazy var properties = Properties<UCheckbox>()
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

	public override var tintColor: UIColor! {
		didSet {
			if isOn == false {
				self.imageView?.tintColor = self.tintColor
			}
		}
	}

	public var isOn: Bool {
		set { self.isOnBinding.wrappedValue = newValue }
		get { self.isOnBinding.wrappedValue }
	}

	private lazy var onImage = UIImage(systemName: "checkmark.square")
	private lazy var offImage = UIImage(systemName: "square")

	private var isOnBinding: UISwift.State<Bool>
	private var imageView: UImage?
	private var onTintColor: UIColor = .blue

	public override init(frame: CGRect) {
		self.isOnBinding = .init(wrappedValue: false)
		super.init(frame: frame)
		setup()
	}

	public init(_ state: UISwift.State<Bool>) {
		isOnBinding = state
		super.init(frame: .zero)
		setup()
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setup() {
		translatesAutoresizingMaskIntoConstraints = false

		body {
			UImage(isOnBinding.map { [weak self] in $0 ? self?.onImage : self?.offImage })
				.bind(isOnBinding) { [weak self] in
					$0.tintColor = $1 ? self?.onTintColor : self?.tintColor
				}
				.userInteraction(false)
				.edgesToSuperview()
				.itself(&imageView)
		}

		addTarget(self, action: #selector(changed), for: .touchUpInside)
	}

	public override func layoutSubviews() {
		super.layoutSubviews()
		onLayoutSubviews()
	}

	public override func didMoveToSuperview() {
		super.didMoveToSuperview()
		movedToSuperview()
	}

	// MARK: Handler

	private var _changed: (Bool) -> Void = { _ in }

	@objc
	private func changed() {
		isOn.toggle()
		_changed(isOn)
	}

	@discardableResult
	public func onChange(_ closure: @escaping (Bool) -> Void) -> Self {
		_changed = closure
		return self
	}

	@discardableResult
	public func onImage(_ image: UIImage) -> Self {
		self.onImage = image
		if self.isOn {
			self.imageView?.image = image
		}
		return self
	}

	@discardableResult
	public func offImage(_ image: UIImage) -> Self {
		self.offImage = image
		if self.isOn == false {
			self.imageView?.image = image
		}
		return self
	}

	@discardableResult
	public func onTint(_ color: UIColor) -> Self {
		self.onTintColor = color
		return self
	}

	@discardableResult
	public func setOn(_ value: Bool = true) -> Self {
		self.isOn = value
		return self
	}
}

extension UCheckbox: _Enableable {
	func _setEnabled(_ v: Bool) {
		isEnabled = v
	}
}
