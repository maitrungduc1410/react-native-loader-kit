#if canImport(SwiftUI) && (canImport(UIKit) || canImport(AppKit))
import SwiftUI
#if canImport(LoaderKitCore)
import LoaderKitCore
#endif

/// A SwiftUI view that draws a LoaderKit indicator, backed by `LoaderKitView`.
///
/// ```swift
/// LoaderKitIndicator("BallPulse", params: ["count": 5])
///     .color(.accentColor)
///     .speed(1.5)
/// ```
public struct LoaderKitIndicator {
    private enum Source {
        case indicator(String)
        case spec(IndicatorSpec)
    }

    private var source: Source
    private var params: [String: Double]
    private var color: Color?
    private var colors: [Color] = []
    private var speed: Double = 1
    private var isAnimating = true
    private var hidesWhenStopped = true
    private var cycleProgress: Double?
    private var respectsReduceMotion = true

    /// A built-in indicator by name.
    public init(_ indicator: String = LoaderKitView.defaultIndicator, params: [String: Double] = [:]) {
        source = .indicator(indicator)
        self.params = params
    }

    /// Any spec, for example one decoded from JSON.
    public init(spec: IndicatorSpec, params: [String: Double] = [:]) {
        source = .spec(spec)
        self.params = params
    }

    public func params(_ params: [String: Double]) -> Self {
        modified { $0.params = params }
    }

    /// Color of every element. `nil` uses the default color.
    public func color(_ color: Color?) -> Self {
        modified { $0.color = color }
    }

    /// Element `i` uses `colors[i % colors.count]`.
    public func colors(_ colors: [Color]) -> Self {
        modified { $0.colors = colors }
    }

    /// Playback speed. Zero or less pauses.
    public func speed(_ speed: Double) -> Self {
        modified { $0.speed = speed }
    }

    public func animating(_ isAnimating: Bool) -> Self {
        modified { $0.isAnimating = isAnimating }
    }

    public func hidesWhenStopped(_ hidesWhenStopped: Bool) -> Self {
        modified { $0.hidesWhenStopped = hidesWhenStopped }
    }

    /// Draws the frozen frame at this point of the animation cycle, in [0, 1]. It is not the
    /// progress of a task. `nil` animates.
    public func cycleProgress(_ cycleProgress: Double?) -> Self {
        modified { $0.cycleProgress = cycleProgress }
    }

    public func respectsReduceMotion(_ respectsReduceMotion: Bool) -> Self {
        modified { $0.respectsReduceMotion = respectsReduceMotion }
    }

    private func modified(_ change: (inout Self) -> Void) -> Self {
        var copy = self
        change(&copy)
        return copy
    }

    @MainActor
    private func makeView() -> LoaderKitView {
        let view = LoaderKitView(frame: .zero)
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        apply(to: view)
        return view
    }

    @MainActor
    private func apply(to view: LoaderKitView) {
        switch source {
        case .indicator(let name): view.indicator = name
        case .spec(let spec): view.spec = spec
        }
        view.params = params
        view.color = color.map { LoaderKitColor($0) } ?? LoaderKitDefaults.color
        view.colors = colors.map { LoaderKitColor($0) }
        view.speed = speed
        view.isAnimating = isAnimating
        view.hidesWhenStopped = hidesWhenStopped
        view.cycleProgress = cycleProgress
        view.respectsReduceMotion = respectsReduceMotion
    }
}

#if canImport(UIKit)
extension LoaderKitIndicator: UIViewRepresentable {
    public func makeUIView(context: Context) -> LoaderKitView {
        makeView()
    }

    public func updateUIView(_ uiView: LoaderKitView, context: Context) {
        apply(to: uiView)
    }
}
#else
extension LoaderKitIndicator: NSViewRepresentable {
    public func makeNSView(context: Context) -> LoaderKitView {
        makeView()
    }

    public func updateNSView(_ nsView: LoaderKitView, context: Context) {
        apply(to: nsView)
    }
}
#endif
#endif
