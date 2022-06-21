//
//  Created by Антон Лобанов on 21.06.2022.
//

import UIKit

public final class ShimmeringView<T: UIView>: UWrapperView<T> {
	@UState private var isShimerring = false

	private var colors: [UIColor] = [
		UIColor(white: 0.85, alpha: 1.0),
		UIColor(white: 0.95, alpha: 1.0),
		UIColor(white: 0.85, alpha: 1.0),
	]

	private var duration: TimeInterval = 0.9

	public override func buildView() {
		super.buildView()
		$isShimerring.listen { [weak self] in
			if $0 {
				self?.startShimmering()
			}
			else {
				self?.stopShimmering()
			}
		}
	}

	@discardableResult
	public func start(_ value: State<Bool>) -> Self {
		value.listen { [weak self] in self?.start($0) }
		return self.start(value.wrappedValue)
	}

	@discardableResult
	public func start(_ value: Bool) -> Self {
		self.isShimerring = value
		return self
	}

	@discardableResult
	public func colors(_ value: [UIColor]) -> Self {
		self.colors = value
		return self
	}

	@discardableResult
	public func duration(_ value: TimeInterval) -> Self {
		self.duration = value
		return self
	}

	func startShimmering() {
		let gradientLayer = CAGradientLayer()
		gradientLayer.name = "shimmeringLayer"
		gradientLayer.frame = self.bounds
		gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
		gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradientLayer.colors = self.colors.map { $0.cgColor }
		gradientLayer.locations = [0.0, 0.5, 1.0]
		self.layer.addSublayer(gradientLayer)

		let animation = CABasicAnimation(keyPath: "locations")
		animation.fromValue = [-1.0, -0.5, 0.0]
		animation.toValue = [1.0, 1.5, 2.0]
		animation.repeatCount = .infinity
		animation.duration = self.duration

		gradientLayer.add(animation, forKey: animation.keyPath)
	}

	func stopShimmering() {
		let gradientLayer = self.layer.sublayers?.first { $0.name == "shimmeringLayer" }
		gradientLayer?.removeAllAnimations()
		gradientLayer?.removeFromSuperlayer()
	}
}
