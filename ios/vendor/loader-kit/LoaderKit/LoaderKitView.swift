#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
#if canImport(LoaderKitCore)
import LoaderKitCore
#endif

#if canImport(UIKit) || canImport(AppKit)
/// A view that draws a LoaderKit indicator, a built-in one by name or any spec.
///
/// Every property can be set on its own and in any order. Changing the spec or the params
/// restarts the animation; changing colors, speed or size does not.
public final class LoaderKitView: LoaderKitPlatformView {
    public nonisolated static let defaultIndicator = "BallPulse"

    private enum Source: Equatable {
        case none
        case indicator(String)
        case spec(IndicatorSpec)
        case json(String)
    }

    private let engine = LoaderKitEngine()

    private var source: Source = .indicator(LoaderKitView.defaultIndicator) {
        didSet { if source != oldValue { applySource() } }
    }

    /// Name of the built-in indicator to draw, `nil` when the spec was set another way.
    public var indicator: String? {
        get {
            if case .indicator(let name) = source { return name }
            return nil
        }
        set { source = newValue.map(Source.indicator) ?? .none }
    }

    /// The spec being drawn. Setting it replaces `indicator` and `specJSON`.
    public var spec: IndicatorSpec? {
        get { engine.spec }
        set { source = newValue.map(Source.spec) ?? .none }
    }

    /// A JSON spec to draw. When it is invalid nothing is drawn and `specError` lists the problems.
    public var specJSON: String? {
        get {
            if case .json(let json) = source { return json }
            return nil
        }
        set { source = newValue.map(Source.json) ?? .none }
    }

    /// Parses and draws a JSON spec, throwing `IndicatorSpecError` when it is invalid.
    public func setSpec(json: String) throws {
        spec = try IndicatorSpec(json: json)
    }

    /// Why nothing is drawn: an unknown indicator name, an invalid spec or params it cannot use.
    public var specError: IndicatorSpecError? {
        engine.error
    }

    /// Overrides for the spec params, by name. Names the spec does not declare are ignored.
    public var params: [String: Double] {
        get { engine.params }
        set {
            engine.setParams(newValue)
            markNeedsLayout()
        }
    }

    /// Color of every element, used when `colors` is empty.
    public var color: LoaderKitColor = LoaderKitDefaults.color {
        didSet { updateColors() }
    }

    /// Element `i` uses `colors[i % colors.count]`. Empty means `color` for every element.
    public var colors: [LoaderKitColor] = [] {
        didSet { updateColors() }
    }

    /// Playback speed, 1 by default. Zero or less pauses.
    public var speed: Double {
        get { engine.speed }
        set { engine.speed = newValue }
    }

    public var isAnimating: Bool {
        get { engine.isAnimating }
        set { engine.isAnimating = newValue }
    }

    /// Whether nothing is drawn while stopped. Default `true`.
    public var hidesWhenStopped: Bool {
        get { engine.hidesWhenStopped }
        set { engine.hidesWhenStopped = newValue }
    }

    /// When set, draws the frozen frame at this point of the animation cycle, in [0, 1], instead of
    /// animating, with every staggered element started. It is not the progress of a task. Clearing
    /// it (or setting NaN) resumes the animation from where it was.
    public var cycleProgress: Double? {
        get { engine.cycleProgress }
        set { engine.cycleProgress = newValue }
    }

    /// Whether the system reduce motion setting replaces the animation with a still frame.
    /// Default `true`.
    public var respectsReduceMotion = true {
        didSet { updateReduceMotion() }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    public convenience init(indicator: String) {
        self.init(frame: CGRect(origin: .zero, size: LoaderKitDefaults.size))
        self.indicator = indicator
    }

    public convenience init(spec: IndicatorSpec) {
        self.init(frame: CGRect(origin: .zero, size: LoaderKitDefaults.size))
        self.spec = spec
    }

    public func startAnimating() {
        isAnimating = true
    }

    public func stopAnimating() {
        isAnimating = false
    }

    /// Restores every property to its default and restarts the animation, for reusing the view.
    public func reset() {
        source = .indicator(Self.defaultIndicator)
        params = [:]
        color = LoaderKitDefaults.color
        colors = []
        speed = 1
        isAnimating = true
        hidesWhenStopped = true
        cycleProgress = nil
        respectsReduceMotion = true
        engine.restartClock()
    }

    public override var intrinsicContentSize: CGSize {
        LoaderKitDefaults.size
    }

    private func commonInit() {
        #if canImport(UIKit)
        layer.addSublayer(engine.rootLayer)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionDidChange),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        #else
        wantsLayer = true
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(reduceMotionDidChange),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
        #endif
        engine.restartClock()
        applySource()
        updateColors()
        updateReduceMotion()
    }

    // MARK: Platform hooks

    #if canImport(UIKit)
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutIndicator()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { reattach() }
    }

    private var contentsScale: CGFloat {
        let scale = traitCollection.displayScale
        return scale > 0 ? scale : 1
    }

    private func markNeedsLayout() {
        setNeedsLayout()
    }

    @objc private func applicationWillEnterForeground() {
        engine.restoreAnimations()
    }
    #else
    public override func makeBackingLayer() -> CALayer {
        let layer = super.makeBackingLayer()
        layer.addSublayer(engine.rootLayer)
        return layer
    }

    public override func layout() {
        super.layout()
        layoutIndicator()
    }

    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        needsLayout = true
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil { reattach() }
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }

    public override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        needsLayout = true
    }

    private var contentsScale: CGFloat {
        window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1
    }

    private func markNeedsLayout() {
        needsLayout = true
    }
    #endif

    // MARK: Updates

    private func layoutIndicator() {
        updateColors()
        engine.layout(bounds: bounds, contentsScale: contentsScale)
    }

    private func reattach() {
        updateReduceMotion()
        engine.restoreAnimations()
        markNeedsLayout()
    }

    private func applySource() {
        switch source {
        case .none:
            engine.setSpec(nil)
        case .indicator(let name):
            if let spec = IndicatorSpec.builtin(named: name) {
                engine.setSpec(spec)
            } else {
                let names = IndicatorSpec.builtinNames.joined(separator: ", ")
                engine.setSpec(nil, error: IndicatorSpecError(problems: [
                    "\"\(name)\" is not a built-in indicator (\(names))",
                ]))
            }
        case .spec(let spec):
            engine.setSpec(spec)
        case .json(let json):
            do {
                engine.setSpec(try IndicatorSpec(json: json))
            } catch let error as IndicatorSpecError {
                engine.setSpec(nil, error: error)
            } catch {
                engine.setSpec(nil, error: IndicatorSpecError(problems: [String(describing: error)]))
            }
        }
        markNeedsLayout()
    }

    /// Colors are resolved here so dynamic colors follow light and dark appearance. UIKit lays
    /// views out again when the appearance changes.
    private func updateColors() {
        let palette = colors.isEmpty ? [color] : colors
        #if canImport(UIKit)
        engine.palette = palette.map { $0.resolvedColor(with: traitCollection).cgColor }
        #else
        var resolved: [CGColor] = []
        effectiveAppearance.performAsCurrentDrawingAppearance {
            resolved = palette.map(\.cgColor)
        }
        engine.palette = resolved
        #endif
    }

    private func updateReduceMotion() {
        #if canImport(UIKit)
        let systemReducesMotion = UIAccessibility.isReduceMotionEnabled
        #else
        let systemReducesMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #endif
        engine.reducesMotion = respectsReduceMotion && systemReducesMotion
    }

    @objc private func reduceMotionDidChange() {
        updateReduceMotion()
    }
}
#endif
