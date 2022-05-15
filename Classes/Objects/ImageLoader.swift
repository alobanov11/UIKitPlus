import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

let cache = NSCache<NSString, NSData>()
let queue = DispatchQueue(label: "com.uiswift.imageloader")

open class ImageCache {
	private let fileManager = FileManager()

	public init() {}

	open func get(_ url: URL) -> _UImage? {
		let cacheData = cache.object(forKey: NSString(string: url.absoluteString)) as Data?
		let localData = self.fileManager.contents(atPath: self.localURL(for: url).path)

		if let data = cacheData, let image = _UImage(data: data) {
			return image
		}
		else if let data = localData, let image = _UImage(data: data) {
			cache.setObject(NSData(data: data), forKey: NSString(string: url.absoluteString))
			return image
		}

		return nil
	}

	open func save(_ url: URL, _ data: Data) {
		cache.setObject(NSData(data: data), forKey: NSString(string: url.absoluteString))
		self.fileManager.createFile(atPath: self.localURL(for: url).path, contents: data, attributes: nil)
	}

	open func localURL(for url: URL) -> URL {
		let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
		return URL(fileURLWithPath: documentDirectoryPath.appendingPathComponent("\(Data(url.absoluteString.utf8).base64EncodedString())"))
	}
}

public final class ImagePreloader {
	public static let shared = ImageLoader()

	private var workItem = DispatchWorkItem {}

	private let imageLoader = ImageLoader()
	private let queue = DispatchQueue(label: "com.uiswift.imagepreloader", qos: .userInitiated)

	public init() {}

	public func preload(_ urls: [URL]) {
		self.imageLoader.cancel()
		self.workItem.cancel()
		self.workItem = DispatchWorkItem { self.start(urls) }
		self.queue.async(execute: self.workItem)
	}

	private func start(_ urls: [URL]) {
		var urls = urls
		guard urls.isEmpty == false else { return }

		let url = urls.removeFirst()

		if self.imageLoader.cache.get(url) == nil {
			self.imageLoader.download(url) { [weak self] in
				if let data = $0 {
					self?.imageLoader.cache.save(url, data)
				}
				self?.start(urls)
			}
		}
		else {
			self.start(urls)
		}
	}
}

public extension ImagePreloader {
	func preload(_ urls: [String?]) {
		self.preload(urls.compactMap { $0 })
	}

	func preload(_ urls: [String]) {
		self.preload(urls.compactMap { URL(string: $0) })
	}
}

open class ImageLoader {
	open var headers: [String: String] = [:]
	open var session: URLSession = .shared

	private var task: URLSessionDataTask?
	private var workItem = DispatchWorkItem {}

	fileprivate let cache = ImageCache()

	public init() {}

	open func cancel() {
		self.task?.cancel()
		self.workItem.cancel()
	}

	open func load(_ url: String?, imageView: _UImageView, defaultImage: _UImage? = nil) {
		self.load(URL(string: url ?? ""), imageView: imageView, defaultImage: defaultImage)
	}

	open func load(_ url: URL?, imageView: _UImageView, defaultImage: _UImage? = nil) {
		imageView.image = defaultImage
		self.cancel()
		self.workItem = DispatchWorkItem { [weak self, weak imageView] in
			guard let url = url, url.absoluteString.count > 0 else {
				DispatchQueue.main.async { imageView?.image = defaultImage }
				return
			}
			if let image = self?.cache.get(url)?.forceLoad()  {
				DispatchQueue.main.async { imageView?.image = image }
			}
			else {
				self?.download(url) { data in
					if let data = data, let image = _UImage(data: data)?.forceLoad() {
						self?.cache.save(url, data)
						DispatchQueue.main.async { imageView?.image = image }
					}
					else {
						DispatchQueue.main.async { imageView?.image = defaultImage }
					}
				}
			}
		}
		queue.async(execute: self.workItem)
	}

	open func download(_ url: URL, completion: @escaping (Data?) -> Void) {
		self.task?.cancel()
		self.task = nil
		if url.isFileURL {
			let data = try? Data(contentsOf: url)
			completion(data)
		}
		else {
			self.task = {
				guard self.headers.isEmpty == false else {
					return URLSession.shared.dataTask(with: url) { data, _, _ in
						completion(data)
					}
				}

				var request = URLRequest(url: url)

				self.headers.forEach {
					request.setValue($0.value, forHTTPHeaderField: $0.key)
				}

				return URLSession.shared.dataTask(with: request) { data, _, _ in
					completion(data)
				}
			}()
			self.task?.resume()
		}
	}
}

extension ImageLoader {
    public static var `default`: ImageLoader { .init() }
}

extension _UImage {
    /// A trick to force draw image on background thread
    func forceLoad() -> _UImage {
        #if os(macOS)
        return self // TODO: figure out
        #else
        guard let imageRef = self.cgImage else {
            return self //failed
        }
        let width = imageRef.width
        let height = imageRef.height
        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let imageContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colourSpace, bitmapInfo: bitmapInfo) else {
            return self //failed
        }
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        imageContext.draw(imageRef, in: rect)
        if let outputImage = imageContext.makeImage() {
            let cachedImage = _UImage(cgImage: outputImage, scale: scale, orientation: imageOrientation)
            return cachedImage
        }
        return self //failed
        #endif
    }
}
