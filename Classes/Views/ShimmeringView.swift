//
//  Created by Антон Лобанов on 21.06.2022.
//

import UIKit

public final class ShimmeringView<T: UIView>: UWrapperView<T> {
	@UState private var isShimerring = false

	private var colors: [UIColor] = [
		.clear,
		.gray.withAlphaComponent(0.7),
		.clear,
	]

	private var duration: TimeInterval = 1.5

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
		gradientLayer.colors = self.colors.map { $0.cgColor }
		gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
		gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradientLayer.frame = self.bounds
		self.layer.mask = gradientLayer

		let animation = CABasicAnimation(keyPath: "transform.translation.x")
		animation.duration = self.duration
		animation.fromValue = -self.frame.size.width
		animation.toValue = self.frame.size.width
		animation.repeatCount = .infinity

		gradientLayer.add(animation, forKey: "shimmeringAnimation")
	}

	func stopShimmering() {
		self.layer.removeAllAnimations()
		self.layer.mask = nil
	}
}
