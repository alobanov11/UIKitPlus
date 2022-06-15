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
    case iPhone4(Any)
    case iPhone5(Any)
    case iPhone6(Any)
    case iPhone6Plus(Any)
    case iPhoneXr(Any)
    case iPhoneX(Any)
    case iPhoneXMax(Any)
	case iPhoneXIdiom(Any)
    case iPad(Any)
    case iPad10(Any)
    case iPad12(Any)

	var value: Any {
		switch self {
		case let .iPhone4(v), let .iPhone5(v), let .iPhone6(v),
			let .iPhone6Plus(v), let .iPhoneXr(v),
			let .iPhoneX(v), let .iPhoneXMax(v),
			let .iPhoneXIdiom(v), let .iPad(v),
			let .iPad10(v), let .iPad12(v):
			return v
		}
	}

	var isActual: Bool {
        switch self {
        case .iPhone4: return UIDevice.isPhone4
        case .iPhone5: return UIDevice.isPhone5
        case .iPhone6: return UIDevice.isPhone6
        case .iPhone6Plus: return UIDevice.isPhone6Plus
        case .iPhoneXr: return UIDevice.isPhoneXr
        case .iPhoneX: return UIDevice.isPhoneX
        case .iPhoneXMax: return UIDevice.isPhoneXMax
		case .iPhoneXIdiom: return UIDevice.isPhoneXIdiom
        case .iPad: return UIDevice.isPad
        case .iPad10: return UIDevice.isPad10
        case .iPad12: return UIDevice.isPad12
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
