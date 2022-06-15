#if os(macOS)

#else
import UIKit

extension UIDevice {
    public class var isPhoneIdiom: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    public class var isPadIdiom: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
#endif
