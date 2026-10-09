#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
#if canImport(QuartzCore)
import QuartzCore
#endif
#if canImport(LoaderKitCore)
import LoaderKitCore
#endif

#if canImport(UIKit) || canImport(AppKit)
/// A progress indicator: linear, circular, pie, gauge, liquid, border, bars, grid or battery.
///
/// Set `value` to a number in [0, 1], or `nil` for the indeterminate animation. With `smooth` on,
/// a new value is reached along a curve that follows the rhythm of the updates and never passes
/// the real value. `contentView` is centered over circular, pie and gauge (a stop button, for
/// example), and framed by border, whose intrinsic size follows it. Bad numbers never throw: they
/// take the defaults.
public final class LoaderKitProgressView: LoaderKitPlatformView {
    private var progressAnimator = ProgressAnimator()
    private var lastFrame: CFTimeInterval?
    #if canImport(UIKit)
    private var displayLink: CADisplayLink?
    private var inBackground = false
    private lazy var progressElement = UIAccessibilityElement(accessibilityContainer: self)
    #else
    private var timer: Timer?
    #endif

    /// The options with every default applied.
    public private(set) var resolvedOptions = ResolvedProgress()
    private var borderContentSize: CGSize?

    /// Every drawing option at once; `nil` options take their defaults.
    public var options = ProgressOptions() {
        didSet {
            guard options != oldValue else { return }
            let previous = resolvedOptions
            resolvedOptions = ResolvedProgress(options)
            if resolvedOptions.type != previous.type || resolvedOptions.linearHeight != previous.linearHeight
                || resolvedOptions.contentInset != previous.contentInset {
                invalidateIntrinsicContentSize()
                markNeedsLayout()
            }
            changed()
        }
    }

    /// Progress in [0, 1]; `nil` or NaN shows the indeterminate animation. Out of range values are clamped.
    public var value: Double? {
        didSet {
            if let value, value.isNaN { self.value = nil }
            guard value != oldValue else { return }
            progressAnimator.setValue(value, now: CACurrentMediaTime(), smooth: smooth && !reducesMotion)
            updateAccessibility()
            changed()
        }
    }

    /// Buffer of linear flat and wavy, in [0, 1]; `nil` draws none.
    public var buffer: Double? {
        didSet {
            if let buffer, buffer.isNaN { self.buffer = nil }
            guard buffer != oldValue else { return }
            progressAnimator.setBuffer(buffer, now: CACurrentMediaTime(), smooth: smooth && !reducesMotion)
            changed()
        }
    }

    /// Move to a new value along a curve rather than jump to it. Default `true`.
    public var smooth = true

    public var type: ProgressType {
        get { resolvedOptions.type }
        set { options.type = newValue }
    }

    public var variant: ProgressVariant {
        get { resolvedOptions.variant }
        set { options.variant = newValue }
    }

    /// Width of strokes and bars in points; `nil` takes the default of the type and variant.
    public var thickness: Double? {
        get { options.thickness }
        set { options.thickness = newValue }
    }

    /// Space between the progress and the track, or between segments, in points.
    public var trackGap: Double? {
        get { options.trackGap }
        set { options.trackGap = newValue }
    }

    /// Number of segments, dots, ticks, steps, bars or grid columns.
    public var segments: Int? {
        get { options.segments == nil ? nil : resolvedOptions.segments }
        set { options.segments = newValue.map(Double.init) }
    }

    public var showLabel: Bool {
        get { resolvedOptions.showLabel }
        set { options.showLabel = newValue }
    }

    /// Dot at the end of the track of linear flat and wavy. Default `true`.
    public var stopIndicator: Bool {
        get { resolvedOptions.stopIndicator }
        set { options.stopIndicator = newValue }
    }

    public var strokeCap: ProgressStrokeCap {
        get { resolvedOptions.strokeCap }
        set { options.strokeCap = newValue }
    }

    /// Wave amplitude of wavy, in points.
    public var amplitude: Double? {
        get { options.amplitude }
        set { options.amplitude = newValue }
    }

    /// Wave length of wavy, in points.
    public var wavelength: Double? {
        get { options.wavelength }
        set { options.wavelength = newValue }
    }

    /// Wave travel in wavelengths per second.
    public var waveSpeed: Double? {
        get { options.waveSpeed }
        set { options.waveSpeed = newValue }
    }

    /// Arc of gauge, in degrees.
    public var sweepAngle: Double? {
        get { options.sweepAngle }
        set { options.sweepAngle = newValue }
    }

    /// Corner radius of border, in points.
    public var cornerRadius: Double? {
        get { options.cornerRadius }
        set { options.cornerRadius = newValue }
    }

    /// Playback rate of the indeterminate animation; zero or negative values pause it, non-finite ones take 1.
    public var speed: Double? {
        get { options.speed }
        set { options.speed = newValue }
    }

    /// Intrinsic width of every type but linear and border, in points. Default 48.
    public var size: CGFloat = CGFloat(ProgressGeometry.defaultSize) {
        didSet {
            if !size.isFinite || size < 0 { size = CGFloat(ProgressGeometry.defaultSize) }
            if size != oldValue { invalidateIntrinsicContentSize() }
        }
    }

    /// `nil` uses the tint color (the accent color on macOS).
    public var color: LoaderKitColor? {
        didSet { markNeedsDisplay() }
    }

    /// `nil` draws the track in `color` at 24% opacity.
    public var trackColor: LoaderKitColor? {
        didSet { markNeedsDisplay() }
    }

    /// `nil` uses the label color.
    public var labelColor: LoaderKitColor? {
        didSet { markNeedsDisplay() }
    }

    /// Whether the system reduce motion setting makes values jump, stops ambient motion and slows
    /// the indeterminate animation down. Default `true`.
    public var respectsReduceMotion = true {
        didSet { changed() }
    }

    /// A view centered over circular, pie and gauge at its intrinsic size, or framed by border.
    public var contentView: LoaderKitPlatformView? {
        didSet {
            guard contentView !== oldValue else { return }
            oldValue?.removeFromSuperview()
            if let contentView { addSubview(contentView) }
            invalidateIntrinsicContentSize()
            markNeedsLayout()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    public convenience init(value: Double?, type: ProgressType = .circular, variant: ProgressVariant? = nil) {
        self.init(frame: .zero)
        options = ProgressOptions(type: type, variant: variant)
        self.value = value.flatMap { $0.isNaN ? nil : $0 }
        progressAnimator = ProgressAnimator(value: self.value)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        #if canImport(AppKit) && !canImport(UIKit)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        #endif
    }

    /// Restores every property to its default, for reusing the view.
    public func reset() {
        options = ProgressOptions()
        smooth = true
        value = nil
        buffer = nil
        size = CGFloat(ProgressGeometry.defaultSize)
        color = nil
        trackColor = nil
        labelColor = nil
        respectsReduceMotion = true
        progressAnimator = ProgressAnimator()
        changed()
    }

    public override var intrinsicContentSize: CGSize {
        let p = resolvedOptions
        switch p.type {
        case .linear:
            return CGSize(width: Self.noIntrinsicMetric, height: CGFloat(p.linearHeight))
        case .border:
            guard let content = contentView?.intrinsicContentSize,
                  content.width != Self.noIntrinsicMetric, content.height != Self.noIntrinsicMetric
            else { return CGSize(width: Self.noIntrinsicMetric, height: Self.noIntrinsicMetric) }
            let inset = CGFloat(p.contentInset)
            return CGSize(width: content.width + 2 * inset, height: content.height + 2 * inset)
        default:
            let ratio = (p.intrinsicSize.height ?? 1) / (p.intrinsicSize.width ?? 1)
            return CGSize(width: size, height: size * CGFloat(ratio))
        }
    }

    private func commonInit() {
        #if canImport(UIKit)
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
        progressElement.accessibilityTraits = .updatesFrequently
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionDidChange),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        #else
        setAccessibilityElement(true)
        setAccessibilityRole(.progressIndicator)
        setAccessibilityMinValue(NSNumber(value: 0))
        setAccessibilityMaxValue(NSNumber(value: 100))
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(reduceMotionDidChange),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowOcclusionDidChange(_:)),
            name: NSWindow.didChangeOcclusionStateNotification,
            object: nil
        )
        #endif
        updateAccessibility()
    }

    // MARK: Motion

    private var reducesMotion: Bool {
        guard respectsReduceMotion else { return false }
        #if canImport(UIKit)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #endif
    }

    private var moving: Bool {
        let speed = resolvedOptions.speed
        return progressAnimator.moving || (progressAnimator.indeterminate && speed > 0 && speed.isFinite)
            || (resolvedOptions.hasAmbientMotion(progressAnimator.state) && !reducesMotion)
    }

    private func changed() {
        updateClock()
        markNeedsDisplay()
    }

    private func updateClock() {
        #if canImport(UIKit)
        let run = window != nil && !isHidden && !inBackground && moving
        if run, displayLink == nil {
            let link = CADisplayLink(target: FrameTarget(self), selector: #selector(FrameTarget.tick(_:)))
            link.add(to: .main, forMode: .common)
            displayLink = link
            lastFrame = nil
        } else if !run, let link = displayLink {
            link.invalidate()
            displayLink = nil
        }
        #else
        let run = window?.occlusionState.contains(.visible) == true && !isHidden && moving
        if run, timer == nil {
            let target = FrameTarget(self)
            let timer = Timer(timeInterval: 1.0 / 60, target: target, selector: #selector(FrameTarget.tick(_:)), userInfo: nil, repeats: true)
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
            lastFrame = nil
        } else if !run, let timer {
            timer.invalidate()
            self.timer = nil
        }
        #endif
    }

    fileprivate func advance() {
        let now = CACurrentMediaTime()
        if let lastFrame {
            // A long pause (the app in the background) should not fast-forward the animation.
            progressAnimator.step(min(0.1, now - lastFrame), speed: resolvedOptions.speed, reduceMotion: reducesMotion)
        }
        lastFrame = now
        markNeedsDisplay()
        if !moving { updateClock() }
    }

    @objc private func reduceMotionDidChange() {
        changed()
    }

    #if canImport(UIKit)
    @objc private func didEnterBackground() {
        inBackground = true
        updateClock()
    }

    @objc private func willEnterForeground() {
        inBackground = false
        updateClock()
    }
    #else
    @objc private func windowOcclusionDidChange(_ notification: Notification) {
        guard let window, notification.object as? NSWindow === window else { return }
        updateClock()
    }
    #endif

    // MARK: Accessibility

    private func updateAccessibility() {
        let percent = value.map { ProgressGeometry.label($0) }
        #if canImport(UIKit)
        progressElement.accessibilityValue = percent
        #else
        setAccessibilityValue(value.map { NSNumber(value: (min(1, max(0, $0)) * 100).rounded()) })
        setAccessibilityValueDescription(percent)
        #endif
    }

    #if canImport(UIKit)
    public override var accessibilityElements: [Any]? {
        get {
            progressElement.accessibilityLabel = accessibilityLabel ?? "Loading"
            progressElement.accessibilityFrameInContainerSpace = bounds
            return [progressElement] + (contentView.map { [$0] } ?? [])
        }
        set {}
    }
    #endif

    // MARK: Platform hooks

    #if canImport(UIKit)
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        updateClock()
    }

    public override var isHidden: Bool {
        didSet { updateClock() }
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()
        setNeedsDisplay()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutContent()
    }

    private func markNeedsDisplay() {
        setNeedsDisplay()
    }

    private func markNeedsLayout() {
        setNeedsLayout()
    }

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let renderer = ProgressRenderer(
            color: (color ?? tintColor).resolvedColor(with: traitCollection).cgColor,
            trackColor: trackColor?.resolvedColor(with: traitCollection).cgColor,
            labelColor: (labelColor ?? .label).resolvedColor(with: traitCollection).cgColor
        )
        render(renderer, in: context)
    }
    #else
    public override var isFlipped: Bool { true }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateClock()
    }

    public override var isHidden: Bool {
        didSet { updateClock() }
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    public override func layout() {
        super.layout()
        layoutContent()
    }

    private func markNeedsDisplay() {
        needsDisplay = true
    }

    private func markNeedsLayout() {
        needsLayout = true
    }

    public override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        var renderer: ProgressRenderer?
        effectiveAppearance.performAsCurrentDrawingAppearance {
            renderer = ProgressRenderer(
                color: (color ?? .controlAccentColor).cgColor,
                trackColor: trackColor?.cgColor,
                labelColor: (labelColor ?? .labelColor).cgColor
            )
        }
        if let renderer { render(renderer, in: context) }
    }
    #endif

    private func render(_ renderer: ProgressRenderer, in context: CGContext) {
        let drawing = ProgressGeometry.commands(resolvedOptions, progressAnimator.state, width: Double(bounds.width), height: Double(bounds.height))
        renderer.draw(drawing, in: context, origin: bounds.origin)
    }

    private func layoutContent() {
        guard let contentView else { return }
        let inset = CGFloat(resolvedOptions.contentInset)
        let area = bounds.insetBy(dx: inset, dy: inset)
        if resolvedOptions.type == .border {
            // The border wraps its content, so content that resizes (a new button title) resizes it.
            let contentSize = contentView.intrinsicContentSize
            if contentSize != borderContentSize {
                borderContentSize = contentSize
                invalidateIntrinsicContentSize()
            }
            contentView.frame = area
            return
        }
        var size = contentView.intrinsicContentSize
        if size.width == Self.noIntrinsicMetric || size.width < 0 { size.width = area.width }
        if size.height == Self.noIntrinsicMetric || size.height < 0 { size.height = area.height }
        contentView.frame = CGRect(x: area.midX - size.width / 2, y: area.midY - size.height / 2, width: size.width, height: size.height)
    }
}

/// Forwards frames to the view without the display link or the timer retaining it, and stops them
/// once the view is gone.
@MainActor
private final class FrameTarget: NSObject {
    private weak var view: LoaderKitProgressView?

    init(_ view: LoaderKitProgressView) {
        self.view = view
    }

    #if canImport(UIKit)
    @objc func tick(_ link: CADisplayLink) {
        guard let view else { return link.invalidate() }
        view.advance()
    }
    #else
    @objc func tick(_ timer: Timer) {
        guard let view else { return timer.invalidate() }
        view.advance()
    }
    #endif
}
#endif
