//
//  Created by Антон Лобанов on 03.03.2022.
//

import Foundation
import UIKit

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
		self.init(AttrStr.parseFromMarkdownToAttributedString(string, attributes: attributes))
	}

	public static func parseFromMarkdownToAttributedString(_ string: String, attributes: MarkdownAttributes) -> NSAttributedString {
		AttrStr(string)
			.addAttribute(.foregroundColor, attributes.body.textColor)
			.addAttribute(.font, attributes.body.font)
			.parseLinkFromMarkdown(attributes.link)
			.parseBoldFromMarkdown(attributes.bold)
			.parseItalicFromMarkdown(attributes.body)
			.attributedString
	}

	public static func parseFromAttributedStringToMarkdown(_ attributedString: NSAttributedString) -> NSAttributedString {
		AttrStr(attributedString)
			.parseBoldToMarkdown()
			.parseItalicToMarkdown()
			.parseLinkToMarkdown()
			.attributedString
	}

	public static func toggleMarkdownAttributeInAttributedString(
		in attributedString: NSAttributedString,
		range: NSRange,
		value: MarkdownAttributeValue,
		attributes: MarkdownAttributes
	) -> NSAttributedString {
		guard attributedString.string.isEmpty == false else {
			return attributedString
		}

		let attributedString = NSMutableAttributedString(attributedString: attributedString)
		let originalString = attributedString.string.substring(with: range.lowerBound ..< range.upperBound)
		let originalAttributedString = NSMutableAttributedString(string: originalString)

		var hasAttribute = false

		(range.lowerBound ..< range.upperBound).enumerated().forEach {
			var attributes = attributedString.attributes(at: $0.element, effectiveRange: nil)
			if attributes.keys.contains(value.key) {
				attributes[value.key] = nil
				hasAttribute = true
			}
			originalAttributedString.addAttributes(attributes, range: NSRange(location: $0.offset, length: 1))
		}

		if hasAttribute == false {
			originalAttributedString.addAttribute(value.key, value: value, range: NSRange(location: 0, length: originalString.count))
		}

		attributedString.replaceCharacters(in: range, with: originalAttributedString)

		let markdownString = self.parseFromAttributedStringToMarkdown(attributedString)

		return self.parseFromMarkdownToAttributedString(markdownString.string, attributes: attributes)
	}
}

private extension AttributedString {
	func parseBoldFromMarkdown(_ attributes: MarkdownAttributeSet) -> AttrStr {
		let regex = "(\\*\\*|__)(?=\\S)(?:.+?[*_]*)(?<=\\S)\\1"
		let result = NSMutableAttributedString(attributedString: self.attributedString)
		var matches = self.matches(regex: regex, string: result.string)

		guard matches.isEmpty == false else { return self }

		repeat {
			let match = matches.removeFirst()

			let originalAttributes = result.attributes(at: match.range.location, longestEffectiveRange: nil, in: match.range)
			let originalString = result.string.substring(with: match.range.lowerBound ..< match.range.upperBound)
			let replacedString = originalString.chopPrefix(2).chopSuffix(2)

			result.replaceCharacters(
				in: match.range,
				with: AttrStr(replacedString)
					.addAttributes(originalAttributes)
					.removeAttribute(.font)
					.addAttribute(.font, (originalAttributes[.font] as? UIFont)?.withTraits(.traitBold) ?? attributes.font.withTraits(.traitBold))
					.addAttribute(MarkdownAttributeKey.bold, MarkdownAttributeValue.bold)
					.attributedString
			)

			matches = self.matches(regex: regex, string: result.string)
		}
		while matches.isEmpty == false

		return AttrStr(result)
	}

	func parseItalicFromMarkdown(_ attributes: MarkdownAttributeSet) -> AttrStr {
		let regex = "(\\*|_)(?=\\S)(.+?)(?<=\\S)\\1"
		let result = NSMutableAttributedString(attributedString: self.attributedString)
		var matches = self.matches(regex: regex, string: result.string)

		guard matches.isEmpty == false else { return self }

		repeat {
			let match = matches.removeFirst()

			let originalAttributes = result.attributes(at: match.range.location, longestEffectiveRange: nil, in: match.range)
			let originalString = result.string.substring(with: match.range.lowerBound ..< match.range.upperBound)
			let replacedString = originalString.chopPrefix(1).chopSuffix(1)

			result.replaceCharacters(
				in: match.range,
				with: AttrStr(replacedString)
					.addAttributes(originalAttributes)
					.removeAttribute(.font)
					.addAttribute(.font, (originalAttributes[.font] as? UIFont)?.withTraits(.traitItalic) ?? attributes.font.withTraits(.traitItalic))
					.addAttribute(MarkdownAttributeKey.italic, MarkdownAttributeValue.italic)
					.attributedString
			)

			matches = self.matches(regex: regex, string: result.string)
		}
		while matches.isEmpty == false

		return AttrStr(result)
	}

	func parseLinkFromMarkdown(_ attributes: MarkdownAttributeSet) -> AttrStr {
		let regex = "\\[([^\\[]+)\\]\\([ \t]*<?(.*?)>?[ \t]*((['\"])(.*?)\\4)?\\)"
		let result = NSMutableAttributedString(attributedString: self.attributedString)
		var matches = self.matches(regex: regex, string: result.string)

		guard matches.isEmpty == false else { return self }

		repeat {
			let match = matches.removeFirst()

			let originalAttributes = result.attributes(at: match.range.location, longestEffectiveRange: nil, in: match.range)
			let titleString = result.string.substring(with: match.range(at: 1).lowerBound ..< match.range(at: 1).upperBound)
			let urlString = result.string.substring(with: match.range(at: 2).lowerBound ..< match.range(at: 2).upperBound)

			result.replaceCharacters(
				in: match.range,
				with: AttrStr(titleString)
					.addAttributes(originalAttributes)
					.removeAttribute(.font)
					.addAttribute(.font, attributes.font)
					.removeAttribute(.foregroundColor)
					.addAttribute(.foregroundColor, attributes.textColor)
					.link(urlString)
					.addAttribute(MarkdownAttributeKey.link, MarkdownAttributeValue.link(urlString))
					.attributedString
			)

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
			let originalAttributes = result.attributes(at: range.location, longestEffectiveRange: nil, in: range)
			let originalString = result.string.substring(with: range.lowerBound ..< range.upperBound)

			result.replaceCharacters(
				in: range,
				with: AttrStr("**\(originalString)**")
					.addAttributes(originalAttributes)
					.removeAttribute(MarkdownAttributeKey.bold)
					.attributedString
			)

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
			let originalAttributes = result.attributes(at: range.location, longestEffectiveRange: nil, in: range)
			let originalString = result.string.substring(with: range.lowerBound ..< range.upperBound)

			result.replaceCharacters(
				in: range,
				with: AttrStr("*\(originalString)*")
					.addAttributes(originalAttributes)
					.removeAttribute(MarkdownAttributeKey.italic)
					.attributedString
			)

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

			let originalAttributes = result.attributes(at: range.location, longestEffectiveRange: nil, in: range)
			let originalString = result.string.substring(with: range.lowerBound ..< range.upperBound)

			result.replaceCharacters(
				in: range,
				with: AttrStr("[\(originalString)](\(urlString))")
					.addAttributes(originalAttributes)
					.removeAttribute(MarkdownAttributeKey.link)
					.attributedString
			)

			ranges = result.attributes(MarkdownAttributeKey.link)
		}
		while ranges.isEmpty == false

		return AttrStr(result)
	}
}

private extension NSMutableAttributedString {
	func attributes(_ key: NSAttributedString.Key) -> [(NSRange, Any)] {
		var ranges: [(NSRange, Any)] = []

		self.attributedString.enumerateAttributes(in: NSRange(location: 0, length: self.attributedString.length), options: []) { attributes, range, _ in
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

	func chopPrefix(_ count: Int) -> String {
		substring(from: index(startIndex, offsetBy: count))
	}

	func chopSuffix(_ count: Int) -> String {
		substring(to: index(endIndex, offsetBy: -count))
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
