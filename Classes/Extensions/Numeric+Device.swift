#if !os(macOS)
import Foundation
import UIKit

precedencegroup NumberByModelPrecedence {
    higherThan: MultiplicationPrecedence
    associativity: left
}

infix operator !! : NumberByModelPrecedence
public func !! <T>(lhs: T, rhs: iPhoneNumeric) -> T where T: BinaryInteger {
    lhs.dev(rhs)
}
public func !! <T>(lhs: T, rhs: iPhoneNumeric) -> T where T: BinaryFloatingPoint {
    lhs.dev(rhs)
}

public enum iPhoneNumeric {
    case iPad(Any)
	case iPhone(Any)

	var value: Any {
		switch self {
		case let .iPad(v), let .iPhone(v):
			return v
		}
	}

	var isActual: Bool {
        switch self {
        case .iPad: return UIDevice.isPadIdiom
        case .iPhone: return UIDevice.isPhoneIdiom
        }
    }
}

extension BinaryInteger {
    func dev(_ model: iPhoneNumeric) -> Self {
		guard model.isActual else { return self }
		return Self(Double(String(describing: model.value)) ?? Double(self))
    }
}

extension BinaryFloatingPoint {
    func dev(_ model: iPhoneNumeric) -> Self {
		guard model.isActual else { return self }
		return Self(Double(String(describing: model.value)) ?? Double(self))
    }
}
#endif
