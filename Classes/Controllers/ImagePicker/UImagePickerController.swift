//
//  Created by Антон Лобанов on 21.02.2022.
//

#if !os(macOS)

import Photos
import UIKit

public final class UImagePickerController: NavigationController<ViewController> {
	public var allowedMediaTypes: Set<PHAssetMediaType>? {
		didSet { self.obtainPhotos() }
	}

	public var allowedMediaSubtypes: PHAssetMediaSubtype? {
		didSet { self.obtainPhotos() }
	}

	public var album: PHAssetCollection? {
		didSet { self.obtainPhotos() }
	}

	public var customPickerItems: [UItemable] = [] {
		didSet { self.obtainPhotos() }
	}

	public var emptyImagesText: String?

	public var emptyAlbumsText: String?

	@UState var countOfSelected = 0

	public private(set) lazy var dismissBarButtonItem = UBarButtonItem("Close")
		.tapAction { self.dismiss(animated: true, completion: nil) }

	public private(set) lazy var doneBarButtonItem = UBarButtonItem("Done")
		.tapAction { self.dismiss(animated: true) { self.done() } }

	public private(set) lazy var titleView = UText("Recent")

	private lazy var fetchOptions: PHFetchOptions = {
		let options = PHFetchOptions()
		options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		options.fetchLimit = self.pageSize
		return options
	}()

	private lazy var collectionLayout = UCollectionViewFlowLayout()
		.minimumLineSpacing(0)
		.minimumInteritemSpacing(0)

	private lazy var collectionViewController = ViewController {
		UCollection(.layout(collectionLayout), $collectionState) {
			switch $0 {
			case let .data(items):
				MultipleSectionBodyItem(self.customPickerItems)
				MultipleSectionBodyItem(items)
			default:
				EmptyItem()
			}
		}
		.onWillDisplay { index in
			let limit = self.fetchOptions.fetchLimit
			guard index.item == limit - 1 else { return }
			self.obtainPhotos(with: limit + self.pageSize)
		}
		.edgesToSuperview()
	}.navigationItem { _, navigationItem in
		navigationItem.leftBarButtonItem = self.dismissBarButtonItem
		navigationItem.titleView = self.titleView
		navigationItem.rightBarButtonItem = self.doneBarButtonItem
	}

	@UState private var collectionState = UCollectionState<[UImagePickerItem]>.empty

	private var photoAssets: PHFetchResult<PHAsset> = PHFetchResult() {
		didSet { self.updateCollectionState() }
	}

	private var onFinishSelecting: (([PHAsset]) -> Void)?

	private let pageSize = 100

	public required override init() {
		super.init()
		self.setViewControllers([self.collectionViewController], animated: false)
		self.modalPresentationStyle = .overFullScreen
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()

		self.requestAuthorization {
			self.obtainPhotos()
		}

		$collectionState.listen { [weak self] in
			self?.countOfSelected = $0.data?.filter { $0.selected }.count ?? 0
		}
	}
}

extension UImagePickerController {
	@discardableResult
	public func selectedBackgroundColor(_ color: UIColor) -> Self {
		UImagePickerCell.selectedBackgroundColor = color
		return self
	}

	@discardableResult
	public func pinBackgroundColor(_ color: UIColor) -> Self {
		UImagePickerCell.pinBackgroundColor = color
		return self
	}

	@discardableResult
	public func albumTitleColor(_ color: UIColor) -> Self {
		UImageAlbumCell.titleColor = color
		return self
	}

	@discardableResult
	public func albumTitleFont(_ font: UIFont) -> Self {
		UImageAlbumCell.titleFont = font
		return self
	}

	@discardableResult
	public func emptyTitleColor(_ color: UIColor) -> Self {
		UImagePickerEmptyCell.titleColor = color
		return self
	}

	@discardableResult
	public func emptyTitleFont(_ font: UIFont) -> Self {
		UImagePickerEmptyCell.titleFont = font
		return self
	}

	@discardableResult
	public func emptyImagesText(_ text: String) -> Self {
		self.emptyImagesText = text
		return self
	}

	@discardableResult
	public func emptyAlbumsText(_ text: String) -> Self {
		self.emptyAlbumsText = text
		return self
	}

	@discardableResult
	public func background(_ color: UIColor) -> Self {
		self.collectionViewController.background(color)
		return self
	}

	@discardableResult
	public func dismissBarButton(configure: (Self, UBarButtonItem) -> Void) -> Self {
		configure(self, self.dismissBarButtonItem)
		return self
	}

	@discardableResult
	public func doneBarButton(configure: (Self, UBarButtonItem) -> Void) -> Self {
		configure(self, self.doneBarButtonItem)
		return self
	}

	@discardableResult
	public func titleView(configure: (Self, UText) -> Void) -> Self {
		configure(self, self.titleView)
		return self
	}

	@discardableResult
	public func onFinish(_ completion: @escaping ([PHAsset]) -> Void) -> Self {
		self.onFinishSelecting = completion
		return self
	}

	@discardableResult
	public func allowedMediaTypes(_ value: Set<PHAssetMediaType>?) -> Self {
		self.allowedMediaTypes = value
		return self
	}

	@discardableResult
	public func allowedMediaSubtypes(_ value: PHAssetMediaSubtype?) -> Self {
		self.allowedMediaSubtypes = value
		return self
	}
}

private extension UImagePickerController {
	func obtainPhotos(with limit: Int? = nil) {
		var predicates: [NSPredicate] = []

		if let allowedMediaTypes = self.allowedMediaTypes {
			let mediaTypesPredicates = allowedMediaTypes.map { NSPredicate(format: "mediaType = %d", $0.rawValue) }
			let allowedMediaTypesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: mediaTypesPredicates)
			predicates += [allowedMediaTypesPredicate]
		}

		if let allowedMediaSubtypes = self.allowedMediaSubtypes {
			let mediaSubtypes = NSPredicate(format: "(mediaSubtype & %d) == 0", allowedMediaSubtypes.rawValue)
			predicates += [mediaSubtypes]
		}

		if predicates.count > 0 {
			let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
			self.fetchOptions.predicate = predicate
		}
		else {
			self.fetchOptions.predicate = nil
		}

		self.fetchOptions.fetchLimit = limit ?? self.pageSize

		self.photoAssets = self.album.map {
			PHAsset.fetchAssets(in: $0, options: self.fetchOptions)
		} ?? PHAsset.fetchAssets(with: self.fetchOptions)
	}

	func updateCollectionState() {
		self.collectionState = .data(Array(0..<self.photoAssets.count).map { index in
			let asset = self.photoAssets.object(at: index)
			return UImagePickerItem(
				asset: asset,
				selected: self.collectionState.data?.first { $0.asset == asset }?.selected ?? false,
				onSelect: { self.selectItem(at: index) }
			)
		})
	}

	func selectItem(at index: Int) {
		guard var data = self.collectionState.data else { return }
		data[index].selected.toggle()
		self.collectionState = .data(data)
	}

	func done() {
		let assets = self.collectionState.data?.filter { $0.selected }.map { $0.asset } ?? []
		self.dismiss(animated: true) {
			self.onFinishSelecting?(assets)
		}
	}

	func showCollections() {
		let smartAlbums = PHAssetCollection.fetchAssetCollections(
			with: .smartAlbum,
			subtype: .albumRegular,
			options: nil
		)

		let userAlbums = PHAssetCollection.fetchAssetCollections(
			with: .album,
			subtype: .albumRegular,
			options: nil
		)

		let albums: [PHAssetCollection] = (
			Array(0..<smartAlbums.count)
				.map { smartAlbums.object(at: $0) }
				.filter { $0.estimatedAssetCount != Int.max }
		) + (
			Array(0..<userAlbums.count)
				.map { userAlbums.object(at: $0) }
				.filter { $0.estimatedAssetCount != Int.max }
		)

		let flowLayout = UCollectionViewFlowLayout()
			.minimumInteritemSpacing(0)
			.minimumInteritemSpacing(0)

		self.pushViewController(ViewController {
			UCollection(.layout(flowLayout)) {
				MultipleSectionBodyItem(albums.map { album in
					UImageAlbumItem(album: album) {
						self.album = album
						self.popViewController(animated: true)
					}
				})
			}
			.edgesToSuperview()
		}.background(self.collectionViewController.view.backgroundColor ?? .clear), animated: true)
	}
}

private extension UImagePickerController {
	func requestAuthorization(completion: @escaping () -> Void) {
		let status = PHPhotoLibrary.authorizationStatus()
		guard status == .notDetermined else {
			completion()
			return
		}
		PHPhotoLibrary.requestAuthorization { _ in
			DispatchQueue.main.async { completion() }
		}
	}
}

#endif
