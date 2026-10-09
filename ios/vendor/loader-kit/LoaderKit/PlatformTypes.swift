#if canImport(UIKit)
import UIKit

public typealias LoaderKitColor = UIColor
public typealias LoaderKitPlatformView = UIView
#elseif canImport(AppKit)
import AppKit

public typealias LoaderKitColor = NSColor
public typealias LoaderKitPlatformView = NSView
#endif

#if canImport(UIKit) || canImport(AppKit)
enum LoaderKitDefaults {
    static let indicator = "BallPulse"
    static let size = CGSize(width: 40, height: 40)
    static var color: LoaderKitColor { .systemGray }
}
#endif
