#if !os(macOS)
import UIKit

open class UCollectionDynamicCell: UCollectionCell {
	open override func preferredLayoutAttributesFitting(
		_ layoutAttributes: UICollectionViewLayoutAttributes
	) -> UICollectionViewLayoutAttributes {
		let size = self.contentView.systemLayoutSizeFitting(layoutAttributes.size)

		var frame = layoutAttributes.frame
		frame.size.height = ceil(size.height)
		layoutAttributes.frame = frame

		return layoutAttributes
	}

    public func setRootView(_ rootView: UIView) {
		self.contentView.subviews.forEach { $0.removeFromSuperview() }
        rootView.translatesAutoresizingMaskIntoConstraints = false
		self.contentView.addSubview(rootView)

		let bottomConstraint = self.contentView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)

		bottomConstraint.priority = .init(999)

        NSLayoutConstraint.activate([
			self.contentView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
			self.contentView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
			self.contentView.topAnchor.constraint(equalTo: rootView.topAnchor),
			bottomConstraint,
        ])
    }
}
#endif
