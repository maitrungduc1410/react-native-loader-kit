import UIKit

/// Hosts `LoaderKitProgressView` for the Fabric component: Objective-C friendly properties with the
/// semantics of the React props. The options arrive resolved from JavaScript.
@objc(LoaderKitProgressContentView)
public final class LoaderKitProgressContentView: UIView {
    private let progress = LoaderKitProgressView(frame: .zero)

    /// Progress in [0, 1]; negative shows the indeterminate animation.
    @objc public var value: Double = -1 {
        didSet { withoutGlideOffscreen { progress.value = value >= 0 ? value : nil } }
    }

    /// Buffer in [0, 1]; negative draws none.
    @objc public var buffer: Double = -1 {
        didSet { withoutGlideOffscreen { progress.buffer = buffer >= 0 ? buffer : nil } }
    }

    @objc public var smooth = true {
        didSet { progress.smooth = smooth }
    }

    @objc public var type = "circular" {
        didSet { progress.options.type = ProgressType(rawValue: type) }
    }

    @objc public var variant = "flat" {
        didSet { progress.options.variant = ProgressVariant(rawValue: variant) }
    }

    @objc public var thickness: Double = 4 {
        didSet { progress.options.thickness = thickness }
    }

    @objc public var trackGap: Double = 4 {
        didSet { progress.options.trackGap = trackGap }
    }

    @objc public var segments: Int = 1 {
        didSet { progress.options.segments = Double(segments) }
    }

    @objc public var showLabel = false {
        didSet { progress.options.showLabel = showLabel }
    }

    @objc public var stopIndicator = true {
        didSet { progress.options.stopIndicator = stopIndicator }
    }

    @objc public var strokeCap = "round" {
        didSet { progress.options.strokeCap = ProgressStrokeCap(rawValue: strokeCap) }
    }

    @objc public var amplitude: Double = 2 {
        didSet { progress.options.amplitude = amplitude }
    }

    @objc public var wavelength: Double = 15 {
        didSet { progress.options.wavelength = wavelength }
    }

    @objc public var waveSpeed: Double = 1 {
        didSet { progress.options.waveSpeed = waveSpeed }
    }

    /// In degrees.
    @objc public var sweepAngle: Double = 270 {
        didSet { progress.options.sweepAngle = sweepAngle }
    }

    @objc public var cornerRadius: Double = 12 {
        didSet { progress.options.cornerRadius = cornerRadius }
    }

    @objc public var speed: Double = 1 {
        didSet { progress.options.speed = speed }
    }

    /// `nil` takes the tint color.
    @objc public var color: UIColor? {
        didSet { progress.color = color }
    }

    /// `nil` draws the track in `color` at 24% opacity.
    @objc public var trackColor: UIColor? {
        didSet { progress.trackColor = trackColor }
    }

    /// `nil` takes the label color.
    @objc public var labelColor: UIColor? {
        didSet { progress.labelColor = labelColor }
    }

    @objc public var respectsReduceMotion = true {
        didSet { progress.respectsReduceMotion = respectsReduceMotion }
    }

    /// What VoiceOver announces; empty means "Loading".
    @objc public var progressAccessibilityLabel = "" {
        didSet { progress.accessibilityLabel = progressAccessibilityLabel.isEmpty ? nil : progressAccessibilityLabel }
    }

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
        progress.reset()
        restoreDefaults()
    }

    private func commonInit() {
        // The drawing takes no touches: they go to the container of LoaderKitProgress.
        isUserInteractionEnabled = false
        progress.frame = bounds
        progress.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(progress)
        restoreDefaults()
    }

    /// Assigns every property, so the options match the default props the component view diffs
    /// against: a prop equal to its default is never sent.
    private func restoreDefaults() {
        value = -1
        buffer = -1
        smooth = true
        type = "circular"
        variant = "flat"
        thickness = 4
        trackGap = 4
        segments = 1
        showLabel = false
        stopIndicator = true
        strokeCap = "round"
        amplitude = 2
        wavelength = 15
        waveSpeed = 1
        sweepAngle = 270
        cornerRadius = 12
        speed = 1
        color = nil
        trackColor = nil
        labelColor = nil
        respectsReduceMotion = true
        progressAccessibilityLabel = ""
    }

    /// A value set before the view is on screen is shown in place rather than glided to.
    private func withoutGlideOffscreen(_ update: () -> Void) {
        guard window == nil else { return update() }
        let smooth = progress.smooth
        progress.smooth = false
        update()
        progress.smooth = smooth
    }
}
