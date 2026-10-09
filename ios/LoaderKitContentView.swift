import UIKit

@objc(LoaderKitReduceMotion)
public enum LoaderKitReduceMotion: Int {
    case system
    case never
    case always
}

/// Hosts `LoaderKitView` for the Fabric component: Objective-C friendly properties with the
/// semantics and defaults of the React props.
@objc(LoaderKitContentView)
public final class LoaderKitContentView: UIView {
    private let loader = LoaderKitView(frame: .zero)

    /// Built-in indicator, used when `specJSON` is empty.
    @objc public var name: String = LoaderKitView.defaultIndicator {
        didSet { applySource() }
    }

    /// A spec serialized as JSON; empty means `name`.
    @objc public var specJSON: String = "" {
        didSet { applySource() }
    }

    /// Param overrides serialized as a JSON object of numbers; empty means none.
    @objc public var paramsJSON: String = "" {
        didSet { applyParams() }
    }

    /// `nil` means white.
    @objc public var color: UIColor? {
        didSet { loader.color = color ?? .white }
    }

    /// Non-empty wins over `color`.
    @objc public var colors: [UIColor] = [] {
        didSet { loader.colors = colors }
    }

    @objc public var speed: Double = 1 {
        didSet { loader.speed = speed }
    }

    @objc public var animating = true {
        didSet { loader.isAnimating = animating }
    }

    @objc public var hidesWhenStopped = false {
        didSet { loader.hidesWhenStopped = hidesWhenStopped }
    }

    /// A frozen point of the animation cycle in [0, 1]; negative means the indicator runs on its
    /// clock.
    @objc public var cycleProgress: Double = -1 {
        didSet { applyCycleProgress() }
    }

    @objc public var reduceMotion: LoaderKitReduceMotion = .system {
        didSet {
            loader.respectsReduceMotion = reduceMotion == .system
            applyCycleProgress()
        }
    }

    /// Why nothing is drawn: an unknown name, an invalid spec or params it cannot use.
    @objc public var specErrorMessage: String? {
        loader.specError?.description
    }

    /// Why `paramsJSON` was ignored, fully or in part.
    @objc public private(set) var paramsErrorMessage: String?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    /// Restores every prop to its default, for a recycled component view.
    @objc public func reset() {
        loader.reset()
        restoreDefaults()
    }

    private func commonInit() {
        loader.frame = bounds
        loader.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(loader)
        restoreDefaults()
    }

    /// Assigns every property so its observer pushes the value to `loader`, whose own defaults
    /// differ from those of the React props.
    private func restoreDefaults() {
        name = LoaderKitView.defaultIndicator
        specJSON = ""
        paramsJSON = ""
        color = nil
        colors = []
        speed = 1
        animating = true
        hidesWhenStopped = false
        cycleProgress = -1
        reduceMotion = .system
    }

    private func applySource() {
        if specJSON.isEmpty {
            loader.indicator = name
        } else {
            loader.specJSON = specJSON
        }
    }

    private func applyParams() {
        paramsErrorMessage = nil
        guard !paramsJSON.isEmpty else {
            loader.params = [:]
            return
        }
        guard
            let object = try? JSONSerialization.jsonObject(with: Data(paramsJSON.utf8)),
            let entries = object as? [String: Any]
        else {
            paramsErrorMessage = "paramsJson is not a JSON object: \(paramsJSON)"
            loader.params = [:]
            return
        }
        var params: [String: Double] = [:]
        var invalid: [String] = []
        for (key, value) in entries {
            if let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() {
                params[key] = number.doubleValue
            } else {
                invalid.append(key)
            }
        }
        if !invalid.isEmpty {
            paramsErrorMessage = "params must be numbers, ignored: \(invalid.sorted().joined(separator: ", "))"
        }
        loader.params = params
    }

    private func applyCycleProgress() {
        if cycleProgress >= 0 {
            loader.cycleProgress = cycleProgress
        } else if reduceMotion == .always {
            loader.cycleProgress = 0
        } else {
            loader.cycleProgress = nil
        }
    }
}
