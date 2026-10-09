import Foundation

/// The shape of a `LoaderKitProgress`.
public enum ProgressType: String, CaseIterable, Hashable, Sendable {
    case linear, circular, pie, gauge, liquid, border, bars, grid, battery, hourglass

    /// The variants this type accepts; the first one is its default.
    public var variants: [ProgressVariant] {
        switch self {
        case .linear: return [.flat, .wavy, .segmented, .striped, .shimmer, .glow, .dots, .steps, .gradient, .center, .chevrons, .ticks]
        case .circular: return [.flat, .wavy, .segmented, .gradient, .ticks, .dots, .glow, .split, .orbit, .dual]
        case .pie: return [.flat, .segmented]
        case .gauge: return [.flat, .segmented, .needle, .gradient, .dots]
        case .liquid: return [.flat, .heart]
        case .border: return [.flat, .glow, .segmented]
        case .bars: return [.flat, .dots, .arcs]
        case .grid: return [.flat, .dots]
        case .battery: return [.flat, .segmented]
        case .hourglass: return [.flat]
        }
    }
}

/// The style of a `LoaderKitProgress` within its type.
public enum ProgressVariant: String, CaseIterable, Hashable, Sendable {
    case flat, wavy, segmented, striped, shimmer, glow, dots, steps, gradient, ticks, center, chevrons, split, orbit, dual, needle, arcs, heart
}

public enum ProgressStrokeCap: String, Hashable, Sendable {
    case round, butt
}

/// Drawing options. Nil options take the defaults of `ResolvedProgress`.
public struct ProgressOptions: Hashable, Sendable {
    public var type: ProgressType?
    public var variant: ProgressVariant?
    /// Width of strokes and bars. Default depends on the type and variant.
    public var thickness: Double?
    /// Space between the progress and the track, or between segments. Default 4.
    public var trackGap: Double?
    /// Number of segments, dots, ticks, steps, bars or grid columns. Default depends on the variant.
    public var segments: Double?
    /// Show the percentage. Default false.
    public var showLabel: Bool?
    /// Dot at the end of the track of linear `flat` and `wavy`. Default true.
    public var stopIndicator: Bool?
    public var strokeCap: ProgressStrokeCap?
    /// Wave amplitude of `wavy`. Default 3 for linear, 2 for circular.
    public var amplitude: Double?
    /// Wave length of `wavy`. Default 40 for linear, 15 for circular.
    public var wavelength: Double?
    /// Wave travel in wavelengths per second. Default 1.
    public var waveSpeed: Double?
    /// Arc of `gauge`, in degrees. Default 270.
    public var sweepAngle: Double?
    /// Corner radius of `border`. Default 12.
    public var cornerRadius: Double?
    /// Playback rate of the indeterminate animation. Default 1.
    public var speed: Double?

    public init(
        type: ProgressType? = nil,
        variant: ProgressVariant? = nil,
        thickness: Double? = nil,
        trackGap: Double? = nil,
        segments: Double? = nil,
        showLabel: Bool? = nil,
        stopIndicator: Bool? = nil,
        strokeCap: ProgressStrokeCap? = nil,
        amplitude: Double? = nil,
        wavelength: Double? = nil,
        waveSpeed: Double? = nil,
        sweepAngle: Double? = nil,
        cornerRadius: Double? = nil,
        speed: Double? = nil
    ) {
        self.type = type
        self.variant = variant
        self.thickness = thickness
        self.trackGap = trackGap
        self.segments = segments
        self.showLabel = showLabel
        self.stopIndicator = stopIndicator
        self.strokeCap = strokeCap
        self.amplitude = amplitude
        self.wavelength = wavelength
        self.waveSpeed = waveSpeed
        self.sweepAngle = sweepAngle
        self.cornerRadius = cornerRadius
        self.speed = speed
    }
}

/// What `ProgressGeometry.commands` draws at one instant; `ProgressAnimator.state` produces it.
public struct ProgressState: Hashable, Sendable {
    public var indeterminate: Bool
    /// Displayed value in [0, 1]; follows the real value when smoothing is on.
    public var value: Double
    /// Displayed buffer in [0, 1]; 0 draws no buffer.
    public var buffer: Double
    /// Wave amplitude factor: 0 flat, 1 full.
    public var wave: Double
    /// Seconds of ambient motion: wave travel, sheens and stripes.
    public var time: Double
    /// Seconds of the indeterminate animation, already scaled by the speed.
    public var indeterminateTime: Double

    public init(indeterminate: Bool, value: Double, buffer: Double = 0, wave: Double = 1, time: Double = 0, indeterminateTime: Double = 0) {
        self.indeterminate = indeterminate
        self.value = value
        self.buffer = buffer
        self.wave = wave
        self.time = time
        self.indeterminateTime = indeterminateTime
    }
}

/// Colors a command refers to. Renderers resolve them from the view's colors.
public enum ProgressColorRole: String, Hashable, Sendable {
    /// The progress color.
    case color
    /// The track color, or the progress color at 24% opacity.
    case track
    /// Label text: the platform text color.
    case label
    case white
}

public struct ProgressColorStop: Hashable, Sendable {
    public var offset: Double
    public var color: ProgressColorRole
    public var alpha: Double

    public init(offset: Double, color: ProgressColorRole, alpha: Double) {
        self.offset = offset
        self.color = color
        self.alpha = alpha
    }
}

public enum ProgressPaint: Hashable, Sendable {
    case solid(color: ProgressColorRole, alpha: Double)
    case linear(x0: Double, y0: Double, x1: Double, y1: Double, stops: [ProgressColorStop])
    case radial(cx: Double, cy: Double, r: Double, stops: [ProgressColorStop])
    /// Offsets are fractions of a turn, clockwise from `start`.
    case conic(cx: Double, cy: Double, start: Double, stops: [ProgressColorStop])
}

public enum ProgressClipShape: Hashable, Sendable {
    case rect(x: Double, y: Double, width: Double, height: Double, radius: Double)
    case circle(cx: Double, cy: Double, r: Double)
    /// Flat list of x, y pairs.
    case polygon(points: [Double])
}

/// One draw command. Coordinates are in points with y pointing down; angles are radians, clockwise.
public indirect enum ProgressCommand: Hashable, Sendable {
    case line(x0: Double, y0: Double, x1: Double, y1: Double, lineWidth: Double, cap: ProgressStrokeCap, paint: ProgressPaint)
    /// Clockwise arc from `start` to `end`.
    case arc(cx: Double, cy: Double, r: Double, start: Double, end: Double, lineWidth: Double, cap: ProgressStrokeCap, paint: ProgressPaint)
    /// Stroked path through x, y pairs, with round joins.
    case polyline(points: [Double], closed: Bool, lineWidth: Double, cap: ProgressStrokeCap, paint: ProgressPaint)
    case circle(cx: Double, cy: Double, r: Double, paint: ProgressPaint)
    /// Filled rectangle with rounded corners.
    case rect(x: Double, y: Double, width: Double, height: Double, radius: Double, paint: ProgressPaint)
    /// Stroked rectangle with rounded corners.
    case strokeRect(x: Double, y: Double, width: Double, height: Double, radius: Double, lineWidth: Double, paint: ProgressPaint)
    /// Filled path through x, y pairs.
    case polygon(points: [Double], paint: ProgressPaint)
    /// Filled pie slice, clockwise from `start` to `end`.
    case sector(cx: Double, cy: Double, r: Double, start: Double, end: Double, paint: ProgressPaint)
    /// Semibold system text, vertically centered on `y`; `x` is the center, or the right edge.
    case text(x: Double, y: Double, size: Double, text: String, alignRight: Bool, paint: ProgressPaint)
    /// Draws `commands` clipped to `shape`.
    case clip(shape: ProgressClipShape, commands: [ProgressCommand])
}

/// What to draw, in a box whose top-left corner is at `x`, `y` in the indicator's bounds.
public struct ProgressDrawing: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var commands: [ProgressCommand]
}
