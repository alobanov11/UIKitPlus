//
//  Created by Антон Лобанов on 03.03.2022.
//

import Foundation
import UIKit

public struct MarkdownFontAttributes: OptionSet {
	public var rawValue: Int32 = 0

	public init(rawValue: Int32) {
		self.rawValue = rawValue
	}

	public static let bold = MarkdownFontAttributes(rawValue: 1 << 0)
	public static let italic = MarkdownFontAttributes(rawValue: 1 << 1)
}

public final class MarkdownAttributeSet {
	public let font: UIFont
	public let textColor: UIColor

	public init(_ font: UIFont, _ textColor: UIColor) {
		self.font = font
		self.textColor = textColor
	}
}

public final class MarkdownAttributes {
	public let body: MarkdownAttributeSet
	public let bold: MarkdownAttributeSet
	public let link: MarkdownAttributeSet

	public init(
		body: MarkdownAttributeSet,
		bold: MarkdownAttributeSet,
		link: MarkdownAttributeSet
	) {
		self.body = body
		self.bold = bold
		self.link = link
	}
}

public enum MarkdownAttributeKey {
	public static let bold = NSAttributedString.Key(rawValue: "Attribute__Bold")
	public static let italic = NSAttributedString.Key(rawValue: "Attribute__Italic")
	public static let link = NSAttributedString.Key(rawValue: "Attribute__Link")

	public static let all = [MarkdownAttributeKey.bold, MarkdownAttributeKey.italic, MarkdownAttributeKey.link]
}

public enum MarkdownAttributeValue {
	case bold
	case italic
	case link(String)

	var key: NSAttributedString.Key {
		switch self {
		case .bold: return MarkdownAttributeKey.bold
		case .italic: return MarkdownAttributeKey.italic
		case .link: return MarkdownAttributeKey.link
		}
	}
}

extension AttributedString {
	public convenience init(_ string: String, attributes: MarkdownAttributes) {
		self.init(AttrStr.convertFromMarkdown(string, attributes: attributes))
	}

	public static func convertFromMarkdown(_ string: String, attributes: MarkdownAttributes) -> NSAttributedString {
		let stateText = AttrStr(string)
			.parseLinkFromMarkdown()
			.parseBoldFromMarkdown()
			.parseItalicFromMarkdown()
			.attributedString

		let result = NSMutableAttributedString(string: stateText.string)
		let fullRange = NSRange(location: 0, length: result.length)

		result.addAttribute(.font, value: attributes.body.font, range: fullRange)
		result.addAttribute(.foregroundColor, value: attributes.body.textColor, range: fullRange)

		stateText.enumerateAttributes(in: fullRange, options: [], using: { attrs, range, _ in
			var fontAttributes: MarkdownFontAttributes = []

			for (key, value) in attrs {
				if key == MarkdownAttributeKey.link, case let .link(url) = value as? MarkdownAttributeValue {
					result.addAttribute(key, value: value, range: range)
					result.addAttribute(.foregroundColor, value: attributes.link.textColor, range: range)
					result.addAttribute(.link, value: url, range: range)
				}
				else if key == MarkdownAttributeKey.bold {
					result.addAttribute(key, value: value, range: range)
					fontAttributes.insert(.bold)
				}
				else if key == MarkdownAttributeKey.italic {
					result.addAttribute(key, value: value, range: range)
					fontAttributes.insert(.italic)
				}
			}

			if fontAttributes.isEmpty == false {
				var font: UIFont?

				if fontAttributes == [.bold, .italic] {
					font = attributes.bold.font.withTraits(.traitItalic)
				}
				else if fontAttributes == [.bold] {
					font = attributes.bold.font
				}
				else if fontAttributes == [.italic] {
					font = attributes.body.font.withTraits(.traitItalic)
				}

				if let font = font {
					result.addAttribute(NSAttributedString.Key.font, value: font, range: range)
				}
			}
		})

		return result
	}

	public static func convertToMarkdown(_ attributedString: NSAttributedString) -> NSAttributedString {
		AttrStr(attributedString)
			.parseBoldToMarkdown()
			.parseItalicToMarkdown()
			.parseLinkToMarkdown()
			.attributedString
	}

	public static func updateMarkdownAttribute(
		in attributedString: NSAttributedString,
		range: NSRange,
		value: MarkdownAttributeValue,
		attributes: MarkdownAttributes
	) -> NSAttributedString {
		guard attributedString.string.isEmpty == false else {
			return attributedString
		}

		let result = NSMutableAttributedString(attributedString: attributedString)
		let hasAttribute = (attributedString.attributedSubstring(from: range).attributes(value.key).isEmpty == false)

		if hasAttribute {
			result.removeAttribute(value.key, range: range)
		}
		else {
			result.addAttribute(value.key, value: value, range: range)
		}

		var intersections = self.intersections(in: result)

		repeat {
			intersections.forEach { result.setAttributes($0.value, range: $0.key) }
			intersections = self.intersections(in: result)
		}
		while intersections.isEmpty == false

		var spaces = self.spaces(in: result)

		repeat {
			spaces.forEach { result.setAttributes(nil, range: NSRange(location: $0, length: 1)) }
			spaces = self.spaces(in: result)
		}
		while spaces.isEmpty == false

		let markdownString = self.convertToMarkdown(result)

		return self.convertFromMarkdown(markdownString.string, attributes: attributes)
	}
}

private extension AttributedString {
	func parseBoldFromMarkdown() -> AttrStr {
		let regex = "(.?|^)(\\*\\*|__)(?=\\S)(.+?)(?<=\\S)(\\2)"
		let result = NSMutableAttributedString(attributedString: self.attributedString)
		var matches = self.matches(regex: regex, string: result.string)

		guard matches.isEmpty == false else { return self }

		repeat {
			let match = matches.removeFirst()

			result.deleteCharacters(in: match.range(at: 4))
			result.addAttribute(MarkdownAttributeKey.bold, value: MarkdownAttributeValue.bold, range: match.range(at: 3))
			result.deleteCharacters(in: match.range(at: 2))

			matches = self.matches(regex: regex, string: result.string)
		}
		while matches.isEmpty == false

		return AttrStr(result)
	}

	func parseItalicFromMarkdown() -> AttrStr {
		let regex = "(.?|^)(\\*|_)(?=\\S)(.+?)(?<![\\*_\\s])(\\2)"
		let result = NSMutableAttributedString(attributedString: self.attributedString)
		var matches = self.matches(regex: regex, string: result.string)

		guard matches.isEmpty == false else { return self }

		repeat {
			let match = matches.removeFirst()

			result.deleteCharacters(in: match.range(at: 4))
			result.addAttribute(MarkdownAttributeKey.italic, value: MarkdownAttributeValue.italic, range: match.range(at: 3))
			result.deleteCharacters(in: match.range(at: 2))

			matches = self.matches(regex: regex, string: result.string)
		}
		while matches.isEmpty == false

		return AttrStr(result)
	}

	func parseLinkFromMarkdown() -> AttrStr {
		let regex = "\\[([^\\[]+)\\]\\([ \t]*<?(.*?)>?[ \t]*((['\"])(.*?)\\4)?\\)"
		let result = NSMutableAttributedString(attributedString: self.attributedString)
		var matches = self.matches(regex: regex, string: result.string)

		guard matches.isEmpty == false else { return self }

		repeat {
			let match = matches.removeFirst()

			let titleString = result.string.substring(with: match.range(at: 1).lowerBound ..< match.range(at: 1).upperBound)
			let urlString = result.string.substring(with: match.range(at: 2).lowerBound ..< match.range(at: 2).upperBound)
			let range = NSRange(location: match.range.location, length: titleString.count)

			result.replaceCharacters(in: match.range, with: titleString)
			result.addAttribute(MarkdownAttributeKey.link, value: MarkdownAttributeValue.link(urlString), range: range)

			matches = self.matches(regex: regex, string: result.string)
		}
		while matches.isEmpty == false

		return AttrStr(result)
	}

	func matches(regex: String, string: String) -> [NSTextCheckingResult] {
		(try? NSRegularExpression(pattern: regex, options: [.caseInsensitive, .anchorsMatchLines]).matches(
			in: string,
			options: NSRegularExpression.MatchingOptions(rawValue: 0),
			range: NSRange(location: 0, length: (string as NSString).length)
		)) ?? []
	}
}

private extension AttributedString {
	func parseBoldToMarkdown() -> AttrStr {
		let result = NSMutableAttributedString(attributedString: self.attributedString)
		var ranges = result.attributes(MarkdownAttributeKey.bold)

		guard ranges.isEmpty == false else { return self }

		repeat {
			let (range, _) = ranges.removeFirst()
			let originalString = NSMutableAttributedString(attributedString: result.attributedSubstring(from: range))

			originalString.insert(NSAttributedString(string: "**"), at: 0)
			originalString.append(NSAttributedString(string: "**"))
			originalString.removeAttribute(MarkdownAttributeKey.bold, range: NSRange(location: 0, length: originalString.length))
			result.replaceCharacters(in: range, with: originalString)

			ranges = result.attributes(MarkdownAttributeKey.bold)
		}
		while ranges.isEmpty == false

		return AttrStr(result)
	}

	func parseItalicToMarkdown() -> AttrStr {
		let result = NSMutableAttributedString(attributedString: self.attributedString)
		var ranges = result.attributes(MarkdownAttributeKey.italic)

		guard ranges.isEmpty == false else { return self }

		repeat {
			let (range, _) = ranges.removeFirst()
			let originalString = NSMutableAttributedString(attributedString: result.attributedSubstring(from: range))

			originalString.insert(NSAttributedString(string: "_"), at: 0)
			originalString.append(NSAttributedString(string: "_"))
			originalString.removeAttribute(MarkdownAttributeKey.italic, range: NSRange(location: 0, length: originalString.length))
			result.replaceCharacters(in: range, with: originalString)

			ranges = result.attributes(MarkdownAttributeKey.italic)
		}
		while ranges.isEmpty == false

		return AttrStr(result)
	}

	func parseLinkToMarkdown() -> AttrStr {
		let result = NSMutableAttributedString(attributedString: self.attributedString)
		var ranges = result.attributes(MarkdownAttributeKey.link)

		guard ranges.isEmpty == false else { return self }

		repeat {
			let (range, value) = ranges.removeFirst()

			guard case let .link(urlString) = value as? MarkdownAttributeValue else {
				break
			}

			let originalString = NSMutableAttributedString(attributedString: result.attributedSubstring(from: range))

			originalString.insert(NSAttributedString(string: "["), at: 0)
			originalString.append(NSAttributedString(string: "](\(urlString))"))
			originalString.removeAttribute(MarkdownAttributeKey.link, range: NSRange(location: 0, length: originalString.length))
			result.replaceCharacters(in: range, with: originalString)

			ranges = result.attributes(MarkdownAttributeKey.link)
		}
		while ranges.isEmpty == false

		return AttrStr(result)
	}
}

private extension AttrStr {
	static func intersections(in attrString: NSAttributedString) -> [NSRange: [NSAttributedString.Key: Any]] {
		var prevAttrs: (attrs: [NSAttributedString.Key: Any], range: NSRange)?
		var intersections: [NSRange: [NSAttributedString.Key: Any]] = [:]

		attrString.enumerateAttributes(in: NSRange(location: 0, length: attrString.length), options: []) { curAttrs, curRange, _ in
			let curKeys = curAttrs.keys.filter { $0.rawValue.contains("Attribute__") }
			let prevKeys = prevAttrs?.attrs.keys.filter { $0.rawValue.contains("Attribute__") }

			if curKeys == prevKeys, let prevRange = prevAttrs?.range {
				intersections[NSRange(location: prevRange.location, length: prevRange.length + curRange.length)] = curAttrs
			}

			prevAttrs = (curAttrs, curRange)
		}

		return intersections
	}

	static func spaces(in attrString: NSAttributedString) -> [Int] {
		var spaces: [Int] = []

		attrString.enumerateAttributes(in: NSRange(location: 0, length: attrString.length), options: []) { curAttrs, curRange, _ in
			if attrString.attributedSubstring(from: curRange).string.last?.isWhitespace == true && curAttrs.isEmpty == false {
				spaces.append(curRange.location + curRange.length - 1)
			}
		}

		return spaces
	}
}

private extension NSAttributedString {
	func attributes(_ key: NSAttributedString.Key) -> [(NSRange, Any)] {
		var ranges: [(NSRange, Any)] = []

		self.enumerateAttributes(in: NSRange(location: 0, length: self.length), options: []) { attributes, range, _ in
			if let value = attributes[key] {
				ranges.append((range, value))
			}
		}

		return ranges
	}
}

private extension String {
	func index(from: Int) -> Index {
		return self.index(startIndex, offsetBy: from)
	}

	func substring(with r: Range<Int>) -> String {
		let startIndex = index(from: r.lowerBound)
		let endIndex = index(from: r.upperBound)
		return String(self[startIndex..<endIndex])
	}
}

private extension UIFont {
	func withTraits(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
		let newTraits = self.fontDescriptor.symbolicTraits.union(UIFontDescriptor.SymbolicTraits(traits))
		guard let descriptor = self.fontDescriptor.withSymbolicTraits(newTraits) else {
			return self
		}
		return UIFont(descriptor: descriptor, size: pointSize)
	}
}
