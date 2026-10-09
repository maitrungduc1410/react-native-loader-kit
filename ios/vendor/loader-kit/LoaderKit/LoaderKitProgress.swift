#if canImport(SwiftUI) && (canImport(UIKit) || canImport(AppKit))
import SwiftUI
#if canImport(LoaderKitCore)
import LoaderKitCore
#endif

/// A SwiftUI progress indicator, backed by `LoaderKitProgressView`.
///
/// Linear fills the width it is offered; border takes the size of its content plus the stroke;
/// the other types are `size` points wide. The content is centered over circular, pie and gauge.
///
/// ```swift
/// LoaderKitProgress(value: upload.fraction) {
///     Button(action: upload.cancel) { Image(systemName: "stop.fill") }
/// }
/// .color(.accentColor)
/// ```
public struct LoaderKitProgress<Content: View>: View {
    private var value: Double?
    private var options: ProgressOptions
    private var smooth = true
    private var buffer: Double?
    private var color: Color?
    private var trackColor: Color?
    private var labelColor: Color?
    private var size: CGFloat = CGFloat(ProgressGeometry.defaultSize)
    private var respectsReduceMotion = true
    private let content: Content

    /// `value` in [0, 1]; `nil` shows the indeterminate animation.
    public init(value: Double?, type: ProgressType = .circular, variant: ProgressVariant? = nil, @ViewBuilder content: () -> Content) {
        self.value = value
        options = ProgressOptions(type: type, variant: variant)
        self.content = content()
    }

    public var body: some View {
        let resolved = ResolvedProgress(options)
        let progress = ProgressRepresentable(
            value: value,
            options: options,
            smooth: smooth,
            buffer: buffer,
            color: color,
            trackColor: trackColor,
            labelColor: labelColor,
            respectsReduceMotion: respectsReduceMotion
        )
        switch resolved.type {
        case .linear:
            progress.frame(maxWidth: .infinity).frame(height: CGFloat(resolved.linearHeight))
        case .border:
            content.padding(CGFloat(resolved.contentInset)).background(progress)
        default:
            let ratio = (resolved.intrinsicSize.height ?? 1) / (resolved.intrinsicSize.width ?? 1)
            progress.frame(width: size, height: size * CGFloat(ratio)).overlay(content)
        }
    }

    /// Move to a new value along a curve rather than jump to it. Default `true`.
    public func smooth(_ smooth: Bool) -> Self { modified { $0.smooth = smooth } }

    /// Buffer of linear flat and wavy, in [0, 1].
    public func buffer(_ buffer: Double?) -> Self { modified { $0.buffer = buffer } }

    /// `nil` uses the tint color.
    public func color(_ color: Color?) -> Self { modified { $0.color = color } }

    /// `nil` draws the track in `color` at 24% opacity.
    public func trackColor(_ color: Color?) -> Self { modified { $0.trackColor = color } }

    /// `nil` uses the label color.
    public func labelColor(_ color: Color?) -> Self { modified { $0.labelColor = color } }

    public func thickness(_ thickness: Double?) -> Self { modified { $0.options.thickness = thickness } }

    public func trackGap(_ trackGap: Double?) -> Self { modified { $0.options.trackGap = trackGap } }

    /// Number of segments, dots, ticks, steps, bars or grid columns.
    public func segments(_ segments: Int?) -> Self { modified { $0.options.segments = segments.map(Double.init) } }

    public func showLabel(_ showLabel: Bool = true) -> Self { modified { $0.options.showLabel = showLabel } }

    public func stopIndicator(_ stopIndicator: Bool) -> Self { modified { $0.options.stopIndicator = stopIndicator } }

    public func strokeCap(_ strokeCap: ProgressStrokeCap) -> Self { modified { $0.options.strokeCap = strokeCap } }

    public func amplitude(_ amplitude: Double?) -> Self { modified { $0.options.amplitude = amplitude } }

    public func wavelength(_ wavelength: Double?) -> Self { modified { $0.options.wavelength = wavelength } }

    /// Wave travel in wavelengths per second.
    public func waveSpeed(_ waveSpeed: Double?) -> Self { modified { $0.options.waveSpeed = waveSpeed } }

    /// Arc of gauge, in degrees.
    public func sweepAngle(_ sweepAngle: Double?) -> Self { modified { $0.options.sweepAngle = sweepAngle } }

    public func cornerRadius(_ cornerRadius: Double?) -> Self { modified { $0.options.cornerRadius = cornerRadius } }

    /// Playback rate of the indeterminate animation. Zero or less pauses it.
    public func speed(_ speed: Double?) -> Self { modified { $0.options.speed = speed } }

    /// Width of every type but linear and border, in points. Default 48.
    public func size(_ size: CGFloat) -> Self { modified { $0.size = size.isFinite && size >= 0 ? size : CGFloat(ProgressGeometry.defaultSize) } }

    public func respectsReduceMotion(_ respectsReduceMotion: Bool) -> Self { modified { $0.respectsReduceMotion = respectsReduceMotion } }

    private func modified(_ change: (inout Self) -> Void) -> Self {
        var copy = self
        change(&copy)
        return copy
    }
}

extension LoaderKitProgress where Content == EmptyView {
    /// `value` in [0, 1]; `nil` shows the indeterminate animation.
    public init(value: Double?, type: ProgressType = .circular, variant: ProgressVariant? = nil) {
        self.init(value: value, type: type, variant: variant) { EmptyView() }
    }
}

private struct ProgressRepresentable {
    var value: Double?
    var options: ProgressOptions
    var smooth: Bool
    var buffer: Double?
    var color: Color?
    var trackColor: Color?
    var labelColor: Color?
    var respectsReduceMotion: Bool

    @MainActor
    func makeView() -> LoaderKitProgressView {
        let view = LoaderKitProgressView(value: value)
        apply(to: view)
        return view
    }

    @MainActor
    func apply(to view: LoaderKitProgressView) {
        view.smooth = smooth
        view.respectsReduceMotion = respectsReduceMotion
        view.options = options
        view.value = value
        view.buffer = buffer
        view.color = color.map { LoaderKitColor($0) }
        view.trackColor = trackColor.map { LoaderKitColor($0) }
        view.labelColor = labelColor.map { LoaderKitColor($0) }
    }
}

#if canImport(UIKit)
extension ProgressRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> LoaderKitProgressView {
        makeView()
    }

    func updateUIView(_ uiView: LoaderKitProgressView, context: Context) {
        apply(to: uiView)
    }
}
#else
extension ProgressRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> LoaderKitProgressView {
        makeView()
    }

    func updateNSView(_ nsView: LoaderKitProgressView, context: Context) {
        apply(to: nsView)
    }
}
#endif
#endif
