#if os(macOS)
import AppKit
#else
import UIKit
#endif

public class TextFieldStyle {
    var font: UFont?
    var textColor: UColor?
    
    public init () {}
}
