//
//  Created by Антон Лобанов on 26.01.2021.
//  Copyright © 2021 Антон Лобанов. All rights reserved.
//

import UIKit

public struct ActionSheetItem
{
	public enum Style
	{
		case destructive
		case `default`
		case cancel
	}

	public let title: String
	public let style: Style
	public let selected: Bool
	public let icon: UIImage?
	public var handler: (() -> Void)?

	public init(
		title: String,
		style: Style = .default,
		selected: Bool = false,
		icon: UIImage? = nil,
		handler: (() -> Void)? = nil
	) {
		self.title = title
		self.style = style
		self.selected = selected
		self.icon = icon
		self.handler = handler
	}
}

public struct ActionSheetItemStyles
{
	public let contentInsets: UIEdgeInsets
	public let height: CGFloat
	public let cornerRadius: CGFloat
	public let backgroundColor: UIColor
	public let tintColor: UIColor
	public let textColor: UIColor
	public let selectedTextColor: UIColor
	public let cancelTextColor: UIColor
	public let destructiveTextColor: UIColor
	public let separatorColor: UIColor
	public let separatorHeight: CGFloat
	public let font: UIFont
	public let horizontalAlignment: UIControl.ContentHorizontalAlignment
	public let iconTitlePadding: CGFloat

	public init(
		contentInsets: UIEdgeInsets = .init(top: 16, left: 20, bottom: 16, right: 20),
		height: CGFloat = 54,
		cornerRadius: CGFloat = 10,
		backgroundColor: UIColor = .lightGray,
		tintColor: UIColor = .black,
		textColor: UIColor = .black,
		selectedTintColor: UIColor = .systemBlue,
		cancelTintColor: UIColor = .systemBlue,
		destructiveTextColor: UIColor = .systemRed,
		separatorColor: UIColor = UIColor.darkGray.withAlphaComponent(0.1),
		separatorHeight: CGFloat = 1,
		font: UIFont = .systemFont(ofSize: 16),
		horizontalAlignment: UIControl.ContentHorizontalAlignment = .center,
		iconTitlePadding: CGFloat = 10
	) {
		self.contentInsets = contentInsets
		self.height = height
		self.cornerRadius = cornerRadius
		self.backgroundColor = backgroundColor
		self.tintColor = tintColor
		self.textColor = textColor
		self.selectedTextColor = selectedTintColor
		self.cancelTextColor = cancelTintColor
		self.destructiveTextColor = destructiveTextColor
		self.separatorColor = separatorColor
		self.separatorHeight = separatorHeight
		self.font = font
		self.horizontalAlignment = horizontalAlignment
		self.iconTitlePadding = iconTitlePadding
	}
}

public struct ActionSheetStyles
{
	public let itemStyles: ActionSheetItemStyles
	public let backgroundColor: UIColor
	public let contentInsets: UIEdgeInsets
	public let sectionInsets: UIEdgeInsets

	public init(
		itemStyles: ActionSheetItemStyles = .init(),
		backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.8),
		contentInsets: UIEdgeInsets = .init(top: 0, left: 10, bottom: 0, right: 10),
		sectionInsets: UIEdgeInsets = .init(top: 0, left: 0, bottom: 10, right: 0)
	) {
		self.itemStyles = itemStyles
		self.backgroundColor = backgroundColor
		self.contentInsets = contentInsets
		self.sectionInsets = sectionInsets
	}
}

final class ActionSheetItemViewCell: UICollectionViewCell
{
	enum Position
	{
		case one
		case first
		case middle
		case last

		var corners: UIRectCorner? {
			switch self {
			case .one: return .allCorners
			case .first: return [.topLeft, .topRight]
			case .middle: return nil
			case .last: return [.bottomLeft, .bottomRight]
			}
		}
	}

	private lazy var titleButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.addTarget(self, action: #selector(self.handleActionTap), for: .touchUpInside)
		return button
	}()

	private lazy var separatorView: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()

	private lazy var separatorHeightConstraint = self.separatorView.heightAnchor.constraint(
		equalToConstant: self.separatorHeight
	)

	private var actionHandler: (() -> Void)?
	private var position: Position = .middle
	private var cornerRadius: CGFloat = 0
	private var separatorHeight: CGFloat = 0

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.addSubviews()
		self.activateConstraints()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.updateCornerRadius()
		self.updateSeparator()
	}

	func fill(
		with action: ActionSheetItem,
		styles: ActionSheetItemStyles,
		position: Position
	) {
		self.titleButton.setImage(action.icon, for: .normal)
		self.titleButton.setTitle(action.title, for: .normal)
		self.titleButton.setTitleColor(
			action.style == .cancel
				? styles.cancelTextColor
				: action.style == .destructive
				? styles.destructiveTextColor
				: action.selected
				? styles.selectedTextColor
				: styles.textColor,
			for: .normal
		)
		self.titleButton.setTitleColor(
			action.selected
				? styles.textColor
				: styles.selectedTextColor,
			for: .highlighted
		)
		self.titleButton.tintColor = styles.tintColor
		self.titleButton.titleLabel?.font = styles.font
		self.titleButton.imageView?.contentMode = .scaleAspectFit
		self.titleButton.contentHorizontalAlignment = action.style == .cancel
			? .center
			: styles.horizontalAlignment
		self.titleButton.contentEdgeInsets = UIEdgeInsets(
			top: styles.contentInsets.top,
			left: styles.contentInsets.left,
			bottom: styles.contentInsets.bottom,
			right: styles.contentInsets.right + (action.icon != nil ? styles.iconTitlePadding : 0)
		)
		self.titleButton.titleEdgeInsets = UIEdgeInsets(
			top: 0,
			left: (action.icon != nil ? styles.iconTitlePadding : 0),
			bottom: 0,
			right: -(action.icon != nil ? styles.iconTitlePadding : 0)
		)
		self.backgroundColor = styles.backgroundColor
		self.separatorView.backgroundColor = styles.separatorColor
		self.separatorHeight = styles.separatorHeight
		self.actionHandler = action.handler
		self.position = position
		self.cornerRadius = styles.cornerRadius
	}

	private func addSubviews() {
		self.contentView.addSubview(self.titleButton)
		self.contentView.addSubview(self.separatorView)
	}

	private func activateConstraints() {
		NSLayoutConstraint.activate([
			self.titleButton.topAnchor.constraint(equalTo: self.contentView.topAnchor),
			self.titleButton.leadingAnchor.constraint(equalTo:  self.contentView.leadingAnchor),
			self.titleButton.trailingAnchor.constraint(equalTo:  self.contentView.trailingAnchor),
			self.titleButton.bottomAnchor.constraint(equalTo:  self.contentView.bottomAnchor),
			self.separatorHeightConstraint,
			self.separatorView.leadingAnchor.constraint(equalTo:  self.contentView.leadingAnchor),
			self.separatorView.trailingAnchor.constraint(equalTo:  self.contentView.trailingAnchor),
			self.separatorView.bottomAnchor.constraint(equalTo:  self.contentView.bottomAnchor),
		])
	}

	private func updateCornerRadius() {
		let path = UIBezierPath(
			roundedRect: self.bounds,
			byRoundingCorners: self.position.corners ?? .allCorners,
			cornerRadii: CGSize(
				width: self.position.corners == nil ? 0 : self.cornerRadius,
				height: self.position.corners == nil ? 0 : self.cornerRadius
			)
		)
		let mask = CAShapeLayer()
		mask.path = path.cgPath
		self.layer.mask = mask
		self.layer.masksToBounds = true
	}

	private func updateSeparator() {
		self.separatorHeightConstraint.constant = (self.position == .first || self.position == .middle)
			? self.separatorHeight
			: 0
	}

	@objc
	private func handleActionTap() {
		self.actionHandler?()
	}
}

/// Must be presented with `animated: false`
public final class ActionSheetController: UIViewController
{
	private var actions = [ActionSheetItem]()
	private let styles: ActionSheetStyles

	private lazy var collectionView: UICollectionView = {
		let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
		collectionView.dataSource = self
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		collectionView.backgroundColor = .clear
		collectionView.scrollIndicatorInsets = .init(
			top: self.styles.sectionInsets.top + self.styles.sectionInsets.bottom,
			left: 0,
			bottom: self.styles.sectionInsets.top + self.styles.sectionInsets.bottom,
			right: 0
		)
		collectionView.layer.cornerRadius = self.styles.itemStyles.cornerRadius
		collectionView.layer.masksToBounds = true
		collectionView.register(
			ActionSheetItemViewCell.self,
			forCellWithReuseIdentifier: String(describing: ActionSheetItemViewCell.self)
		)
		collectionView.register(
			ActionSheetItemViewCell.self,
			forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
			withReuseIdentifier: String(describing: ActionSheetItemViewCell.self)
		)
		return collectionView
	}()

	private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .vertical
		return layout
	}()

	private lazy var collectionViewBottomConstraint: NSLayoutConstraint = {
		let constraint = self.collectionView.bottomAnchor.constraint(equalTo:  self.view.safeAreaLayoutGuide.bottomAnchor)
		constraint.constant = self.view.frame.height
		return constraint
	}()

	public init(
		actions: [ActionSheetItem],
		styles: ActionSheetStyles = .init()
	) {
		self.styles = styles
		super.init(nibName: nil, bundle: nil)
		self.actions = actions.map { action in
			var action = action
			let originalHandler = action.handler
			action.handler = { [weak self] in
				self?.dismiss(originalHandler)
			}
			return action
		}
		self.modalTransitionStyle = .crossDissolve
		self.modalPresentationStyle = .overFullScreen
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		self.addSubviews()
		self.activateConstraints()
		self.applyStyles()
		self.addGestures()
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.viewAppear()
	}

	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.viewDisappear()
	}

	private func addSubviews() {
		self.view.addSubview(self.collectionView)
	}

	private func activateConstraints() {
		NSLayoutConstraint.activate([
			self.collectionView.heightAnchor.constraint(equalToConstant: self.heightForCollectionView()),
			self.collectionView.leftAnchor.constraint(
				equalTo: self.view.safeAreaLayoutGuide.leftAnchor,
				constant: self.styles.contentInsets.left
			),
			self.collectionView.rightAnchor.constraint(
				equalTo: self.view.safeAreaLayoutGuide.rightAnchor,
				constant: -self.styles.contentInsets.right
			),
			self.collectionViewBottomConstraint,
		])
	}

	private func applyStyles() {
		self.view.backgroundColor = self.styles.backgroundColor.withAlphaComponent(0)
		self.collectionViewLayout.itemSize = .init(
			width: UIScreen.main.bounds.width - (self.styles.contentInsets.left + self.styles.contentInsets.right),
			height: self.styles.itemStyles.height
		)
		self.collectionViewLayout.footerReferenceSize = .init(
			width: UIScreen.main.bounds.width - (self.styles.contentInsets.left + self.styles.contentInsets.right),
			height: self.styles.itemStyles.height
		)
		self.collectionViewLayout.sectionFootersPinToVisibleBounds = true
		self.collectionViewLayout.minimumLineSpacing = 0
		self.collectionViewLayout.minimumInteritemSpacing = 0
		self.collectionViewLayout.sectionInset = self.styles.sectionInsets
		self.collectionView.contentInset = .init(
			top: self.styles.contentInsets.top,
			left: 0,
			bottom: self.styles.contentInsets.bottom,
			right: 0
		)
	}

	private func addGestures() {
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleDismissTap))
		self.view.addGestureRecognizer(tapGesture)
	}

	private func heightForCollectionView() -> CGFloat {
		let items = CGFloat(self.actions.filter { $0.style != .cancel }.count)
		let cancelHeight: CGFloat = self.actions.contains(where: { $0.style == .cancel })
			? self.styles.itemStyles.height + self.styles.sectionInsets.bottom
			: 0
		let originalHeight = items * self.styles.itemStyles.height + cancelHeight
		let safeAreaHeight = self.view.safeAreaLayoutGuide.layoutFrame.size.height - cancelHeight - self.styles.sectionInsets.bottom
		return originalHeight > safeAreaHeight ? safeAreaHeight : originalHeight
	}

	private func viewAppear() {
		self.collectionView.scrollToItem(
			at: IndexPath(item: self.actions.filter { $0.style != .cancel }.count - 1, section: 0),
			at: .centeredVertically,
			animated: false
		)
		UIView.animate(
			withDuration: 0.3,
			delay: 0,
			options: [.transitionFlipFromBottom]
		) {
			self.collectionViewBottomConstraint.constant = 0
			self.view.backgroundColor = self.styles.backgroundColor
			self.view.layoutIfNeeded()
		}
	}

	private func viewDisappear() {
		UIView.animate(
			withDuration: 0.3,
			delay: 0,
			options: [.transitionFlipFromTop]
		) {
			self.collectionViewBottomConstraint.constant = self.view.frame.height
			self.view.backgroundColor = self.styles.backgroundColor.withAlphaComponent(0)
			self.view.layoutIfNeeded()
		}
	}

	@objc
	private func handleDismissTap() {
		self.dismiss()
	}

	private func dismiss(_ completion: (() -> Void)? = nil) {
		self.dismiss(animated: true, completion: completion)
	}
}

extension ActionSheetController: UICollectionViewDataSource
{
	public func collectionView(
		_ collectionView: UICollectionView,
		numberOfItemsInSection section: Int
	) -> Int {
		self.actions.filter { $0.style != .cancel }.count
	}

	public func collectionView(
		_ collectionView: UICollectionView,
		cellForItemAt indexPath: IndexPath
	) -> UICollectionViewCell {
		guard self.actions.filter({ $0.style != .cancel }).indices.contains(indexPath.item),
			  let cell = collectionView.dequeueReusableCell(
				withReuseIdentifier: String(describing: ActionSheetItemViewCell.self),
				for: indexPath
			  ) as? ActionSheetItemViewCell
		else {
			return UICollectionViewCell()
		}
		cell.fill(
			with: self.actions[indexPath.item],
			styles: self.styles.itemStyles,
			position: self.actions.filter({ $0.style != .cancel }).count == 1
				? .one
				: indexPath.item == 0
				? .first
				: indexPath.item == self.actions.filter({ $0.style != .cancel }).count - 1
				? .last
				: .middle
		)
		return cell
	}

	public func collectionView(
		_ collectionView: UICollectionView,
		viewForSupplementaryElementOfKind kind: String,
		at indexPath: IndexPath
	) -> UICollectionReusableView {
		guard
			let action = self.actions.first(where: { $0.style == .cancel }),
			let view = collectionView.dequeueReusableSupplementaryView(
				ofKind: kind,
				withReuseIdentifier: String(describing: ActionSheetItemViewCell.self),
				for: indexPath
			) as? ActionSheetItemViewCell
		else {
			return UICollectionReusableView()
		}
		view.fill(with: action, styles: self.styles.itemStyles, position: .one)
		return view
	}
}
