import Foundation

/// Options with every default applied and every number made safe to draw with.
public struct ResolvedProgress: Hashable, Sendable {
    public var type: ProgressType
    public var variant: ProgressVariant
    public var thickness: Double
    public var trackGap: Double
    public var segments: Int
    public var showLabel: Bool
    public var stopIndicator: Bool
    public var strokeCap: ProgressStrokeCap
    public var amplitude: Double
    public var wavelength: Double
    public var waveSpeed: Double
    /// Radians.
    public var sweepAngle: Double
    public var cornerRadius: Double
    public var speed: Double

    private static let thicknessDefaults: [String: Double] = [
        "linear:flat": 4, "linear:wavy": 4, "linear:segmented": 6, "linear:striped": 10, "linear:shimmer": 8,
        "linear:glow": 3, "linear:dots": 4, "linear:steps": 3, "circular:gradient": 5, "circular:ticks": 3,
        "gauge": 6, "liquid": 3, "border": 3, "battery": 3,
    ]
    private static let segmentDefaults: [String: Double] = [
        "linear:segmented": 10, "linear:dots": 8, "linear:steps": 4, "circular:segmented": 12, "circular:ticks": 12,
        "circular:dots": 10, "gauge:segmented": 10, "bars": 5, "grid": 5,
    ]

    /// Applies the defaults: a variant the type does not have becomes its default, non-finite numbers
    /// take the default, sizes are not negative and segments are whole numbers within limits.
    public init(_ options: ProgressOptions = ProgressOptions()) {
        let type = options.type ?? .circular
        let variants = type.variants
        let variant = options.variant.flatMap { variants.contains($0) ? $0 : nil } ?? variants[0]
        let key = "\(type.rawValue):\(variant.rawValue)"
        let linear = type == .linear
        func finite(_ value: Double?, _ fallback: Double) -> Double {
            guard let value, value.isFinite else { return fallback }
            return value
        }
        let segmentsDefault = Self.segmentDefaults[key] ?? Self.segmentDefaults[type.rawValue] ?? 1
        let segmentsMin = key == "linear:steps" ? 2 : 1
        let segmentsMax = type == .grid ? 16 : 64
        let sweepDegrees = min(350, max(30, finite(options.sweepAngle, 270)))
        self.type = type
        self.variant = variant
        thickness = max(0.5, finite(options.thickness, Self.thicknessDefaults[key] ?? Self.thicknessDefaults[type.rawValue] ?? 4))
        trackGap = max(0, finite(options.trackGap, 4))
        segments = min(segmentsMax, max(segmentsMin, Int(min(1e6, max(-1e6, floor(finite(options.segments, segmentsDefault) + 0.5))))))
        showLabel = options.showLabel ?? false
        stopIndicator = options.stopIndicator ?? true
        strokeCap = options.strokeCap ?? .round
        amplitude = max(0, finite(options.amplitude, linear ? 3 : 2))
        wavelength = max(minWavelength, finite(options.wavelength, linear ? 40 : 15))
        waveSpeed = finite(options.waveSpeed, 1)
        sweepAngle = sweepDegrees * .pi / 180
        cornerRadius = max(0, finite(options.cornerRadius, 12))
        speed = finite(options.speed, 1)
    }

    /// True when `segments` changes how this type and variant draw.
    public var usesSegments: Bool {
        Self.segmentDefaults["\(type.rawValue):\(variant.rawValue)"] != nil || type == .bars || type == .grid
    }

    /// True when a linear label sits inside the bar rather than after it.
    public var labelInside: Bool {
        type == .linear && showLabel && thickness >= 14 && (variant == .flat || variant == .striped || variant == .shimmer)
    }

    /// True when the indicator moves even with a fixed value (waves, stripes, sheens, liquid). With a
    /// state, a wave that has flattened out does not count.
    public func hasAmbientMotion(_ state: ProgressState? = nil) -> Bool {
        if type == .liquid || variant == .striped || variant == .shimmer { return true }
        return variant == .wavy && (state.map { $0.wave > 0 } ?? true)
    }

    /// Height of a linear indicator, which takes its width from the layout.
    public var linearHeight: Double {
        let t = thickness
        var height: Double
        switch variant {
        case .wavy: height = t + 2 * amplitude + 4
        case .glow: height = t + 18
        case .dots: height = max(6, t * 2) * 2.3
        case .steps: height = 2 * max(7, t * 1.75) + 4
        default: height = t + 4
        }
        if showLabel && !labelInside { height = max(height, 18) }
        return ceil(height)
    }

    /// The size a layout gives the indicator when nothing else sizes it. Nil means no preference:
    /// linear fills the available width, and `border` takes the size of its content plus `contentInset`.
    public var intrinsicSize: (width: Double?, height: Double?) {
        let size = ProgressGeometry.defaultSize
        switch type {
        case .linear: return (nil, linearHeight)
        case .border: return (nil, nil)
        case .bars: return (size, size * 0.75)
        case .battery: return (size, size / 2)
        default: return (size, size)
        }
    }

    /// Padding between a `border` and its content, so the stroke does not cover it.
    public var contentInset: Double {
        type == .border ? thickness + trackGap : 0
    }
}

/// Turns resolved options and an animation state into draw commands, the same on every platform.
public enum ProgressGeometry {
    /// Default width and height of every type that does not fill its container or wrap its content.
    public static let defaultSize: Double = 48
    /// Room a linear label takes after the bar when it does not fit inside.
    public static let labelWidth: Double = 44

    /// The percentage text of the labels.
    public static func label(_ value: Double) -> String {
        "\(Int(floor(clamp01(value) * 100 + 0.5)))%"
    }

    /// Fill order of the grid cells: diagonal by diagonal from the top-left, top row first.
    public static func gridOrder(_ columns: Int) -> [Int] {
        guard columns > 0 else { return [] }
        var rank = [Int](repeating: 0, count: columns * columns)
        var next = 0
        if columns > 0 {
            for d in 0...(2 * (columns - 1)) {
                for r in max(0, d - columns + 1)...min(d, columns - 1) {
                    rank[r * columns + (d - r)] = next
                    next += 1
                }
            }
        }
        return rank
    }

    /// The draw commands for `p` in a `width` x `height` box. Linear and border fill the box; bars
    /// keep a 4:3 shape, battery 2:1 and the other types a square, centered in the box.
    public static func commands(_ p: ResolvedProgress, _ s: ProgressState, width: Double, height: Double) -> ProgressDrawing {
        var b = Builder(p: p, s: s)
        guard width > 0, height > 0, width.isFinite, height.isFinite else { return ProgressDrawing(x: 0, y: 0, commands: []) }
        switch p.type {
        case .linear:
            b.linearAny(width, height)
            return ProgressDrawing(x: 0, y: 0, commands: b.out)
        case .border:
            b.border(width, height)
            return ProgressDrawing(x: 0, y: 0, commands: b.out)
        case .bars:
            let w = min(width, height * 4 / 3)
            let h = w * 3 / 4
            b.bars(w, h)
            return ProgressDrawing(x: (width - w) / 2, y: (height - h) / 2, commands: b.out)
        case .battery:
            let w = min(width, height * 2)
            let h = w / 2
            b.battery(w, h)
            return ProgressDrawing(x: (width - w) / 2, y: (height - h) / 2, commands: b.out)
        default:
            let size = min(width, height)
            switch p.type {
            case .circular: b.circularAny(size)
            case .pie: b.pie(size)
            case .gauge: b.gauge(size)
            case .liquid: b.liquid(size)
            default: b.grid(size)
            }
            return ProgressDrawing(x: (width - size) / 2, y: (height - size) / 2, commands: b.out)
        }
    }
}

private let tau = Double.pi * 2
private let top = -Double.pi / 2
private let minWavySize: Double = 32

/// Shorter waves alias: the wave is sampled every 2 units of length.
private let minWavelength: Double = 8

private func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }
/// `x` modulo `m`, always in [0, m).
private func mod(_ x: Double, _ m: Double) -> Double { x - floor(x / m) * m }
private func roundHalfUp(_ x: Double) -> Double { floor(x + 0.5) }
private func steps(_ x: Double) -> Int { Int(ceil(x - 1e-9)) }
private func bump(_ d: Double, _ width: Double) -> Double {
    let x = abs(d) / width
    return x >= 1 ? 0 : 0.5 + 0.5 * cos(Double.pi * x)
}
private func emphasized(_ x: Double) -> Double { cubicBezierEase(x1: 0.2, y1: 0, x2: 0, y2: 1, x: x) }
private func standard(_ x: Double) -> Double { cubicBezierEase(x1: 0.4, y1: 0, x2: 0.2, y2: 1, x: x) }
private func easeInOut(_ x: Double) -> Double { cubicBezierEase(x1: 0.65, y1: 0, x2: 0.35, y2: 1, x: x) }
private func solid(_ color: ProgressColorRole, _ alpha: Double = 1) -> ProgressPaint { .solid(color: color, alpha: alpha) }

private func rectClip(_ x: Double, _ y: Double, _ width: Double, _ height: Double, _ radius: Double) -> ProgressClipShape {
    .rect(x: x, y: y, width: width, height: height, radius: max(0, min(radius, width / 2, height / 2)))
}

/// Active segments of the indeterminate linear indicator, as (start, end) fractions of the track.
private func linearSegments(_ u: Double) -> [(Double, Double)] {
    let head1 = emphasized(clamp01(u / 0.55))
    let tail1 = standard(clamp01((u - 0.15) / 0.55))
    let head2 = emphasized(clamp01((u - 0.5) / 0.42))
    let tail2 = standard(clamp01((u - 0.62) / 0.38))
    var segments: [(Double, Double)] = []
    if head1 - tail1 > 0.002 { segments.append((tail1, head1)) }
    if head2 - tail2 > 0.002 { segments.append((tail2, head2)) }
    // The second segment enters on the left while the first is still leaving on the right.
    if segments.count == 2, segments[1].0 < segments[0].0 { segments.reverse() }
    return segments
}

/// Arc of the indeterminate circular indicator, as (start, end) angles clockwise from the top.
private func circularArc(_ time: Double) -> (Double, Double) {
    let cycle = 1.4
    let k = floor(time / cycle)
    let u = mod(time / cycle, 1)
    let head = easeInOut(clamp01(u / 0.5)) * 0.72
    let tail = easeInOut(clamp01((u - 0.5) / 0.5)) * 0.72
    let base = mod(k * 0.72 + time / 2.2, 1)
    return ((base + tail) * tau, (base + head) * tau + 0.12)
}

private func labelSize(_ size: Double) -> Double { max(10, min(size * 0.22, 44)) }

private func sheen(_ x: Double, _ width: Double, _ color: ProgressColorRole, _ peak: Double) -> ProgressPaint {
    .linear(x0: x, y0: 0, x1: x + width, y1: 0, stops: [
        ProgressColorStop(offset: 0, color: color, alpha: 0),
        ProgressColorStop(offset: 0.5, color: color, alpha: peak),
        ProgressColorStop(offset: 1, color: color, alpha: 0),
    ])
}

private func fade(_ cx: Double, _ cy: Double, _ r: Double, _ alpha: Double) -> ProgressPaint {
    .radial(cx: cx, cy: cy, r: r, stops: [
        ProgressColorStop(offset: 0, color: .color, alpha: alpha),
        ProgressColorStop(offset: 1, color: .color, alpha: 0),
    ])
}

private struct BorderPath {
    var points: [Double]
    var lengths: [Double]
    var total: Double
}

private let bolt: [Double] = [0.15, -1, -0.55, 0.12, -0.05, 0.12, -0.2, 1, 0.55, -0.15, 0.05, -0.15]

private struct Builder {
    let p: ResolvedProgress
    let s: ProgressState
    var out: [ProgressCommand] = []

    init(p: ResolvedProgress, s: ProgressState) {
        self.p = p
        self.s = s
    }

    // MARK: primitives

    mutating func hLine(_ x0: Double, _ x1: Double, _ y: Double, _ lineWidth: Double, _ cap: ProgressStrokeCap, _ paint: ProgressPaint) {
        guard x1 >= x0 else { return }
        out.append(.line(x0: x0, y0: y, x1: x1, y1: y, lineWidth: lineWidth, cap: cap, paint: paint))
    }

    mutating func arc(_ cx: Double, _ cy: Double, _ r: Double, _ start: Double, _ end: Double, _ lineWidth: Double, _ cap: ProgressStrokeCap, _ paint: ProgressPaint) {
        guard end > start, r > 0 else { return }
        out.append(.arc(cx: cx, cy: cy, r: r, start: start, end: end, lineWidth: lineWidth, cap: cap, paint: paint))
    }

    mutating func circle(_ cx: Double, _ cy: Double, _ r: Double, _ paint: ProgressPaint) {
        guard r > 0 else { return }
        out.append(.circle(cx: cx, cy: cy, r: r, paint: paint))
    }

    mutating func rect(_ x: Double, _ y: Double, _ width: Double, _ height: Double, _ radius: Double, _ paint: ProgressPaint) {
        guard width > 0, height > 0 else { return }
        out.append(.rect(x: x, y: y, width: width, height: height, radius: max(0, min(radius, width / 2, height / 2)), paint: paint))
    }

    mutating func text(_ x: Double, _ y: Double, _ size: Double, _ value: String, right: Bool = false, _ paint: ProgressPaint) {
        out.append(.text(x: x, y: y, size: size, text: value, alignRight: right, paint: paint))
    }

    /// Runs `body` into a fresh list and returns what it drew.
    mutating func nested(_ body: (inout Builder) -> Void) -> [ProgressCommand] {
        var inner = Builder(p: p, s: s)
        body(&inner)
        return inner.out
    }

    /// The label in the text color, and again in white where `fill` covers it.
    mutating func invertedLabel(_ value: String, _ x: Double, _ y: Double, _ size: Double, _ fill: ProgressClipShape) {
        text(x, y, size, value, solid(.label))
        out.append(.clip(shape: fill, commands: [.text(x: x, y: y, size: size, text: value, alignRight: false, paint: solid(.white))]))
    }

    mutating func wave(_ x0: Double, _ x1: Double, _ y: Double, _ amp: Double, _ wavelength: Double, _ phase: Double, _ lineWidth: Double, _ cap: ProgressStrokeCap, _ paint: ProgressPaint) {
        guard x1 >= x0 else { return }
        let n = max(1, steps((x1 - x0) / 2))
        var points: [Double] = []
        points.reserveCapacity(2 * n + 2)
        for i in 0...n {
            let x = x0 + (x1 - x0) * Double(i) / Double(n)
            points.append(x)
            points.append(y + amp * sin((x - phase) / wavelength * tau))
        }
        out.append(.polyline(points: points, closed: false, lineWidth: lineWidth, cap: cap, paint: paint))
    }

    mutating func wavyArc(_ cx: Double, _ cy: Double, _ r: Double, _ amp: Double, _ waves: Double, _ phase: Double, _ start: Double, _ end: Double, _ lineWidth: Double, _ cap: ProgressStrokeCap, _ paint: ProgressPaint) {
        guard end > start else { return }
        let n = max(8, steps((end - start) * r / 1.5))
        var points: [Double] = []
        points.reserveCapacity(2 * n + 2)
        for i in 0...n {
            let a = start + (end - start) * Double(i) / Double(n)
            let rr = r + amp * sin(waves * a - phase)
            points.append(cx + rr * cos(a))
            points.append(cy + rr * sin(a))
        }
        out.append(.polyline(points: points, closed: false, lineWidth: lineWidth, cap: cap, paint: paint))
    }

    // MARK: linear

    mutating func linearAny(_ w: Double, _ h: Double) {
        let inside = p.labelInside
        let outside = p.showLabel && !inside
        // A bar narrower than 20 next to the label is unreadable, so the label is left out instead.
        let labelFits = !outside || w - ProgressGeometry.labelWidth >= 20
        let barWidth = outside && labelFits ? w - ProgressGeometry.labelWidth : w
        switch p.variant {
        case .segmented: linearSegmented(barWidth, h)
        case .striped: linearStriped(barWidth, h)
        case .shimmer: linearShimmer(barWidth, h)
        case .glow: linearGlow(barWidth, h)
        case .dots: linearDots(barWidth, h)
        case .steps: linearSteps(barWidth, h)
        default: linear(barWidth, h)
        }
        guard !s.indeterminate, p.showLabel, labelFits else { return }
        let label = ProgressGeometry.label(s.value)
        if outside {
            text(w, h / 2, 12.5, label, right: true, solid(.label))
            return
        }
        let t = p.thickness
        let v = clamp01(s.value)
        let r = p.strokeCap == .round ? t / 2 : 0
        let filled = p.variant == .flat ? (v > 0.0005 ? v * (w - 2 * r) + 2 * r : 0) : v * w
        invertedLabel(label, w / 2, h / 2, roundHalfUp(min(t * 0.6, 15)), rectClip(0, 0, filled, h, 0))
    }

    mutating func linear(_ w: Double, _ h: Double) {
        let t = p.thickness
        let cap = p.strokeCap
        let r = cap == .round ? t / 2 : 0
        let cy = h / 2
        let x0 = r
        let x1 = w - r
        let len = x1 - x0
        let wavy = p.variant == .wavy
        let amp = wavy ? p.amplitude * s.wave : 0
        let wavelength = p.wavelength
        let phase = mod(s.time * p.waveSpeed, 1) * wavelength
        let gap = p.trackGap + 2 * r
        let color = solid(.color)
        let track = solid(.track)
        func active(_ b: inout Builder, _ from: Double, _ to: Double) {
            if wavy && amp > 0.05 {
                b.wave(x0 + from * len, x0 + to * len, cy, amp, wavelength, phase, t, cap, color)
            } else {
                b.hLine(x0 + from * len, x0 + to * len, cy, t, cap, color)
            }
        }
        if s.indeterminate {
            var from = 0.0
            for (a, b) in linearSegments(mod(s.indeterminateTime / 1.75, 1)) {
                let end = a * len - (from == 0 && a == 0 ? 0 : gap)
                if end > from { hLine(x0 + from, x0 + end, cy, t, cap, track) }
                from = b * len + gap
                active(&self, a, b)
            }
            if from < len { hLine(x0 + from, x1, cy, t, cap, track) }
            return
        }
        let v = clamp01(s.value)
        var trackFrom = v > 0.0005 ? v * len + gap : 0
        if s.buffer > 0 {
            let b = max(v, clamp01(s.buffer))
            if b * len - trackFrom > 0.5 {
                hLine(x0 + trackFrom, x0 + b * len, cy, t, cap, solid(.color, 0.5))
                trackFrom = b * len + gap
            }
        }
        if trackFrom < len { hLine(x0 + trackFrom, x1, cy, t, cap, track) }
        if p.stopIndicator && trackFrom < len - t { circle(x1, cy, min(t, 4) / 2, color) }
        if v > 0.0005 { active(&self, 0, v) }
    }

    mutating func linearSegmented(_ w: Double, _ h: Double) {
        let n = p.segments
        let t = p.thickness
        let y = h / 2 - t / 2
        let gap = max(2, p.trackGap)
        let width = (w - gap * Double(n - 1)) / Double(n)
        let radius = p.strokeCap == .round ? min(t / 2, width / 2) : 0
        let center = mod(s.indeterminateTime / 1.6, 1) * Double(n + 4) - 2
        for i in 0..<n {
            let x = Double(i) * (width + gap)
            rect(x, y, width, t, radius, solid(.track))
            var fill = 1.0
            var alpha = 1.0
            if s.indeterminate {
                alpha = bump(Double(i) + 0.5 - center, 2.2)
            } else {
                fill = clamp01(clamp01(s.value) * Double(n) - Double(i))
            }
            if fill <= 0.001 || alpha <= 0.01 || width <= 0 { continue }
            let inner = nested { $0.rect(x, y, width * fill, t, 0, solid(.color, alpha)) }
            out.append(.clip(shape: rectClip(x, y, width, t, radius), commands: inner))
        }
    }

    mutating func stripes(_ to: Double, _ y: Double, _ t: Double, _ spacing: Double, _ offset: Double, _ paint: ProgressPaint) {
        var x = -t - spacing * 2 + offset
        while x < to + t {
            out.append(.polygon(points: [x, y + t, x + spacing, y + t, x + spacing + t, y, x + t, y], paint: paint))
            x += spacing * 2
        }
    }

    mutating func linearStriped(_ w: Double, _ h: Double) {
        let t = p.thickness
        let y = h / 2 - t / 2
        let radius = t / 2
        let spacing = max(6, t * 0.8)
        let offset = mod((s.indeterminate ? s.indeterminateTime : s.time) * 26, spacing * 2)
        rect(0, y, w, t, radius, solid(.track))
        let s = self.s
        let inner = nested { b in
            if s.indeterminate {
                b.stripes(w, y, t, spacing, offset, solid(.color, 0.85))
            } else {
                let filled = w * clamp01(s.value)
                if filled > 0.5 {
                    let fill = b.nested { f in
                        f.rect(0, y, filled, t, 0, solid(.color))
                        f.stripes(filled, y, t, spacing, offset, solid(.white, 0.22))
                    }
                    b.out.append(.clip(shape: rectClip(0, y, filled, t, radius), commands: fill))
                }
            }
        }
        if !inner.isEmpty { out.append(.clip(shape: rectClip(0, y, w, t, radius), commands: inner)) }
    }

    mutating func linearShimmer(_ w: Double, _ h: Double) {
        let t = p.thickness
        let y = h / 2 - t / 2
        let radius = t / 2
        rect(0, y, w, t, radius, solid(.track))
        let s = self.s
        let inner = nested { b in
            if s.indeterminate {
                let u = mod(s.indeterminateTime / 1.5, 1)
                let width = w * 0.45
                let x = -width + easeInOut(u) * (w + width)
                b.rect(x, y, width, t, 0, sheen(x, width, .color, 1))
            } else {
                let filled = w * clamp01(s.value)
                if filled > 0.5 {
                    let fill = b.nested { f in
                        f.rect(0, y, filled, t, 0, solid(.color))
                        let u = mod(s.time, 2.2) / 1.5
                        if u < 1 {
                            let width = max(36, w * 0.22)
                            let x = -width + u * (filled + width)
                            f.rect(x, y, width, t, 0, sheen(x, width, .white, 0.5))
                        }
                    }
                    b.out.append(.clip(shape: rectClip(0, y, filled, t, radius), commands: fill))
                }
            }
        }
        if !inner.isEmpty { out.append(.clip(shape: rectClip(0, y, w, t, radius), commands: inner)) }
    }

    mutating func linearGlow(_ w: Double, _ h: Double) {
        let t = p.thickness
        let cy = h / 2
        let cap = p.strokeCap
        let r = cap == .round ? t / 2 : 0
        let x0 = r + 2
        let x1 = w - r - 2
        let len = x1 - x0
        hLine(x0, x1, cy, t, cap, solid(.color, 0.14))
        func glow(_ b: inout Builder, _ from: Double, _ to: Double) {
            let head = x0 + to * len
            b.hLine(x0 + from * len, head, cy, t + 8, cap, solid(.color, 0.12))
            b.hLine(x0 + from * len, head, cy, t + 4, cap, solid(.color, 0.22))
            b.hLine(x0 + from * len, head, cy, t, cap, solid(.color))
            let reach = t + 8
            b.rect(head - reach, cy - reach, 2 * reach, 2 * reach, 0, fade(head, cy, reach, 0.55))
        }
        if s.indeterminate {
            for (a, b) in linearSegments(mod(s.indeterminateTime / 1.75, 1)) { glow(&self, a, b) }
            return
        }
        let v = clamp01(s.value)
        if v > 0.0005 { glow(&self, 0, v) }
    }

    mutating func linearDots(_ w: Double, _ h: Double) {
        let n = p.segments
        let d = max(6, p.thickness * 2)
        let r = d / 2
        let cy = h / 2 + r * 0.45
        let spacing = (w - d) / Double(max(1, n - 1))
        let center = mod(s.indeterminateTime / 1.5, 1) * Double(n + 3) - 1.5
        for i in 0..<n {
            let x = r + Double(i) * spacing
            circle(x, cy, r, solid(.track))
            if s.indeterminate {
                let k = bump(Double(i) - center, 1.6)
                if k > 0 { circle(x, cy - k * r * 0.9, r * (0.75 + 0.25 * k), solid(.color, k)) }
            } else {
                let fill = clamp01(clamp01(s.value) * Double(n) - Double(i))
                if fill > 0 { circle(x, cy, r * fill.squareRoot(), solid(.color)) }
            }
        }
    }

    mutating func linearSteps(_ w: Double, _ h: Double) {
        let n = p.segments
        let t = p.thickness
        let R = max(7, t * 1.75)
        let cy = h / 2
        let gap = 3.0
        let xs = (0..<n).map { R + Double($0) * (w - 2 * R) / Double(n - 1) }
        let position = s.indeterminate ? -1 : clamp01(s.value) * Double(n - 1)
        let center = mod(s.indeterminateTime / 2.2, 1) * Double(n) - 0.5
        for i in 0..<(n - 1) {
            let a = xs[i] + R + gap
            let b = xs[i + 1] - R - gap
            hLine(a, b, cy, t, .round, solid(.track))
            if s.indeterminate {
                let lo = clamp01(center - 0.3 - Double(i))
                let hi = clamp01(center + 0.3 - Double(i))
                if hi > lo { hLine(a + (b - a) * lo, a + (b - a) * hi, cy, t, .round, solid(.color)) }
            } else {
                let fill = clamp01(position - Double(i))
                if fill > 0 { hLine(a, a + (b - a) * fill, cy, t, .round, solid(.color)) }
            }
        }
        for i in 0..<n {
            let x = xs[i]
            circle(x, cy, R, solid(.track))
            if s.indeterminate {
                let k = bump(Double(i) - center, 0.55)
                if k > 0.01 { circle(x, cy, R, solid(.color, k)) }
                continue
            }
            let done = clamp01((position - Double(i) + 0.12) / 0.12)
            if done > 0 {
                circle(x, cy, R * (0.4 + 0.6 * done), solid(.color))
                if done > 0.6 {
                    out.append(.polyline(
                        points: [x - R * 0.38, cy + R * 0.02, x - R * 0.1, cy + R * 0.3, x + R * 0.4, cy - R * 0.28],
                        closed: false,
                        lineWidth: max(1.5, R * 0.22),
                        cap: .round,
                        paint: solid(.white, (done - 0.6) / 0.4)
                    ))
                }
            } else if position > Double(i) - 1 {
                arc(x, cy, R - 1, 0, tau, 2, .butt, solid(.color))
            }
        }
    }

    // MARK: circular family

    mutating func circularAny(_ size: Double) {
        switch p.variant {
        case .segmented: segmentedArc(size / 2, size / 2, (size - p.thickness) / 2, top, tau, true)
        case .gradient: circularGradient(size)
        case .ticks: circularTicks(size)
        case .dots: circularDots(size)
        default: circular(size)
        }
        if p.showLabel && !s.indeterminate {
            text(size / 2, size / 2, labelSize(size), ProgressGeometry.label(s.value), solid(.label))
        }
    }

    mutating func circular(_ size: Double) {
        let t = p.thickness
        let cap = p.strokeCap
        let wavy = p.variant == .wavy && size >= minWavySize
        let ampMax = wavy ? p.amplitude : 0
        let amp = ampMax * s.wave
        let cx = size / 2
        let cy = size / 2
        let r = (size - t) / 2 - ampMax
        guard r > 0 else { return }
        let gapAngle = (p.trackGap + (cap == .round ? t : 0)) / r
        let waves = max(3, roundHalfUp(tau * r / p.wavelength))
        let phase = mod(s.time * p.waveSpeed, 1) * tau
        let color = solid(.color)
        let track = solid(.track)
        func active(_ b: inout Builder, _ start: Double, _ end: Double) {
            if wavy && amp > 0.05 {
                b.wavyArc(cx, cy, r, amp, waves, phase, start, end, t, cap, color)
            } else {
                b.arc(cx, cy, r, start, end, t, cap, color)
            }
        }
        if s.indeterminate {
            let (a0, a1) = circularArc(s.indeterminateTime)
            arc(cx, cy, r, top + a1 + gapAngle, top + a0 + tau - gapAngle, t, cap, track)
            active(&self, top + a0, top + a1)
            return
        }
        let v = clamp01(s.value)
        if v <= 0.0005 {
            arc(cx, cy, r, 0, tau, t, .butt, track)
            return
        }
        let sweep = v * tau
        if p.trackGap > 0 || v < 1 { arc(cx, cy, r, top + sweep + gapAngle, top + tau - gapAngle, t, cap, track) }
        active(&self, top, top + max(sweep, 0.0001))
    }

    /// Segments spread over `sweep` from `start`; a full circle also gets a gap at the seam.
    mutating func segmentedArc(_ cx: Double, _ cy: Double, _ r: Double, _ start: Double, _ sweep: Double, _ full: Bool) {
        guard r > 0 else { return }
        let n = p.segments
        let count = Double(n)
        let t = p.thickness
        let cap = p.strokeCap
        let gapAngle = (max(2, p.trackGap) + (cap == .round ? t : 0)) / r
        let segment = (sweep - gapAngle * (full ? count : count - 1)) / count
        guard segment > 0.01 else { return }
        let it = s.indeterminateTime
        let center = full ? mod(it / 1.2, 1) * count : (0.5 - 0.5 * cos(it * Double.pi)) * count
        for i in 0..<n {
            let a0 = start + Double(i) * (segment + gapAngle) + (full ? gapAngle / 2 : 0)
            arc(cx, cy, r, a0, a0 + segment, t, cap, solid(.track))
            if s.indeterminate {
                var d = Double(i) + 0.5 - center
                if full {
                    let m = mod(d, count)
                    d = min(m, count - m)
                }
                let k = bump(d, full ? count * 0.32 : 2)
                if k > 0.01 { arc(cx, cy, r, a0, a0 + segment, t, cap, solid(.color, k)) }
            } else {
                let fill = clamp01(clamp01(s.value) * count - Double(i))
                if fill > 0.001 { arc(cx, cy, r, a0, a0 + segment * fill, t, cap, solid(.color)) }
            }
        }
    }

    mutating func circularGradient(_ size: Double) {
        let t = p.thickness
        let cx = size / 2
        let cy = size / 2
        let r = (size - t) / 2 - 1
        arc(cx, cy, r, 0, tau, t, .butt, solid(.track))
        let head: Double
        let tail: Double
        if s.indeterminate {
            let it = s.indeterminateTime
            head = top + mod(it / 1.1, 1) * tau
            tail = head - (0.62 + 0.12 * sin(it * 2.4)) * tau
        } else {
            let v = clamp01(s.value)
            guard v > 0.0005 else { return }
            tail = top
            head = top + v * tau
        }
        arc(cx, cy, r, tail, head, t, .butt, .conic(cx: cx, cy: cy, start: tail, stops: [
            ProgressColorStop(offset: 0, color: .color, alpha: s.indeterminate ? 0 : 0.12),
            ProgressColorStop(offset: min(1, (head - tail) / tau), color: .color, alpha: 1),
        ]))
        let hx = cx + r * cos(head)
        let hy = cy + r * sin(head)
        circle(hx, hy, t * 1.25, fade(hx, hy, t * 1.25, 0.5))
        circle(hx, hy, t / 2, solid(.color))
    }

    mutating func circularTicks(_ size: Double) {
        let n = p.segments
        let count = Double(n)
        let t = p.thickness
        let outer = size / 2 - t / 2
        let inner = outer * 0.52
        let cx = size / 2
        let cy = size / 2
        let lead = mod(floor(s.indeterminateTime * count), count)
        for i in 0..<n {
            let a = top + Double(i) * tau / count
            let ca = cos(a)
            let sa = sin(a)
            func tick(_ paint: ProgressPaint) -> ProgressCommand {
                .line(x0: cx + inner * ca, y0: cy + inner * sa, x1: cx + outer * ca, y1: cy + outer * sa, lineWidth: t, cap: p.strokeCap, paint: paint)
            }
            if s.indeterminate {
                out.append(tick(solid(.color, 1 - mod(lead - Double(i), count) / count * 0.85)))
                continue
            }
            out.append(tick(solid(.track)))
            let fill = clamp01(clamp01(s.value) * count - Double(i))
            if fill > 0 { out.append(tick(solid(.color, fill))) }
        }
    }

    mutating func circularDots(_ size: Double) {
        let n = p.segments
        let count = Double(n)
        let dr = max(1.5, p.thickness * 0.75)
        let r = size / 2 - dr * 1.35
        let cx = size / 2
        let cy = size / 2
        let center = mod(s.indeterminateTime / 1.1, 1) * count
        for i in 0..<n {
            let a = top + Double(i) * tau / count
            let x = cx + r * cos(a)
            let y = cy + r * sin(a)
            circle(x, y, dr, solid(.track))
            if s.indeterminate {
                let alpha = max(0, 1 - mod(center - Double(i), count) / (count * 0.6))
                if alpha > 0 { circle(x, y, dr * (0.7 + 0.35 * alpha), solid(.color, alpha)) }
                continue
            }
            let fill = clamp01(clamp01(s.value) * count - Double(i))
            if fill > 0 { circle(x, y, dr * fill.squareRoot(), solid(.color)) }
        }
    }

    mutating func pie(_ size: Double) {
        let t = max(1, p.thickness * 0.6)
        let cx = size / 2
        let cy = size / 2
        let ring = (size - t) / 2
        let inner = ring - t / 2 - max(1, p.trackGap * 0.6)
        arc(cx, cy, ring, 0, tau, t, .butt, solid(.color))
        circle(cx, cy, inner, solid(.track))
        var start = top
        let end: Double
        if s.indeterminate {
            let u = s.indeterminateTime / 1.2
            start += mod(u, 1) * tau
            end = start + (0.12 + 0.2 * (0.5 - 0.5 * cos(u * tau))) * tau
        } else {
            end = start + clamp01(s.value) * tau
        }
        guard end - start >= 0.0005, inner > 0 else { return }
        out.append(.sector(cx: cx, cy: cy, r: inner, start: start, end: end, paint: solid(.color)))
    }

    mutating func gauge(_ size: Double) {
        let t = p.thickness
        let cap = p.strokeCap
        let cx = size / 2
        let cy = size / 2
        let r = (size - t) / 2
        let sweep = p.sweepAngle
        let start = Double.pi / 2 + (tau - sweep) / 2
        let end = start + sweep
        if r > 0 {
            let gapAngle = (p.trackGap + (cap == .round ? t : 0)) / r
            if p.variant == .segmented {
                segmentedArc(cx, cy, r, start, sweep, false)
            } else if s.indeterminate {
                let length = 0.24 * sweep
                let a = start + (0.5 - 0.5 * cos(s.indeterminateTime * Double.pi)) * (sweep - length)
                arc(cx, cy, r, start, a - gapAngle, t, cap, solid(.track))
                arc(cx, cy, r, a + length + gapAngle, end, t, cap, solid(.track))
                arc(cx, cy, r, a, a + length, t, cap, solid(.color))
            } else {
                let v = clamp01(s.value)
                if v <= 0.0005 {
                    arc(cx, cy, r, start, end, t, cap, solid(.track))
                } else {
                    arc(cx, cy, r, start + v * sweep + gapAngle, end, t, cap, solid(.track))
                    arc(cx, cy, r, start, start + v * sweep, t, cap, solid(.color))
                }
            }
        }
        if p.showLabel && !s.indeterminate {
            text(cx, cy, labelSize(size), ProgressGeometry.label(s.value), solid(.label))
        }
    }

    func liquidSurface(_ cx: Double, _ cy: Double, _ inner: Double, _ level: Double, _ amp: Double, _ wavelength: Double, _ phase: Double) -> [Double] {
        let y = cy + inner - level * 2 * inner
        let left = cx - inner
        let right = cx + inner + 2
        let n = max(1, steps((right - left) / 2))
        var points = [left, cy + inner + 1]
        points.reserveCapacity(2 * n + 6)
        for i in 0...n {
            let x = left + (right - left) * Double(i) / Double(n)
            points.append(x)
            points.append(y + amp * sin(x / wavelength * tau + phase))
        }
        points.append(right)
        points.append(cy + inner + 1)
        return points
    }

    mutating func liquid(_ size: Double) {
        let ring = max(1.5, p.thickness * 0.6)
        let cx = size / 2
        let cy = size / 2
        let R = (size - ring) / 2
        let inner = R - ring / 2 - max(1.5, p.trackGap * 0.6)
        arc(cx, cy, R, 0, tau, ring, .butt, solid(.color))
        guard inner > 0 else { return }
        let level = s.indeterminate ? 0.5 + 0.14 * sin(s.indeterminateTime * 1.8) : clamp01(s.value)
        let amp = inner * (s.indeterminate ? 0.09 : 0.07 * s.wave)
        let wavelength = inner * 1.35
        let cycles = s.time * p.waveSpeed * 0.8
        let front = liquidSurface(cx, cy, inner, level, amp, wavelength, mod(cycles, 1) * tau)
        let back = liquidSurface(cx, cy, inner, level, amp * 0.8, wavelength, 2 - mod(cycles * 0.7, 1) * tau)
        let p = self.p
        let s = self.s
        let content = nested { b in
            b.rect(cx - inner, cy - inner, inner * 2, inner * 2, 0, solid(.track))
            b.out.append(.polygon(points: back, paint: solid(.color, 0.45)))
            b.out.append(.polygon(points: front, paint: solid(.color)))
            if p.showLabel && !s.indeterminate {
                b.invertedLabel(ProgressGeometry.label(s.value), cx, cy, labelSize(size), .polygon(points: front))
            }
        }
        out.append(.clip(shape: .circle(cx: cx, cy: cy, r: inner), commands: content))
    }

    // MARK: border

    /// Rounded rectangle path starting at the top center, clockwise, sampled about every 2 points.
    func borderPath(_ w: Double, _ h: Double, _ inset: Double, _ radius: Double) -> BorderPath {
        let L = inset
        let T = inset
        let R = w - inset
        let B = h - inset
        let r = max(0, min(radius, (R - L) / 2, (B - T) / 2))
        let mx = (L + R) / 2
        var points = [mx, T]
        func line(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) {
            let n = max(1, steps(hypot(x1 - x0, y1 - y0) / 2))
            for i in 1...n {
                points.append(x0 + (x1 - x0) * Double(i) / Double(n))
                points.append(y0 + (y1 - y0) * Double(i) / Double(n))
            }
        }
        func corner(_ cx: Double, _ cy: Double, _ a0: Double) {
            guard r > 0 else { return }
            let n = max(2, steps(r * Double.pi / 4))
            for i in 1...n {
                let a = a0 + Double.pi / 2 * (Double(i) / Double(n))
                points.append(cx + r * cos(a))
                points.append(cy + r * sin(a))
            }
        }
        line(mx, T, R - r, T)
        corner(R - r, T + r, -Double.pi / 2)
        line(R, T + r, R, B - r)
        corner(R - r, B - r, 0)
        line(R - r, B, L + r, B)
        corner(L + r, B - r, Double.pi / 2)
        line(L, B - r, L, T + r)
        corner(L + r, T + r, Double.pi)
        line(L + r, T, mx, T)
        var lengths = [0.0]
        var i = 2
        while i < points.count {
            lengths.append(lengths[lengths.count - 1] + hypot(points[i] - points[i - 2], points[i + 1] - points[i - 1]))
            i += 2
        }
        return BorderPath(points: points, lengths: lengths, total: lengths[lengths.count - 1])
    }

    /// Strokes the part of `path` from fraction `a` to fraction `b`; `b` above 1 wraps past the start.
    mutating func strokeAlong(_ path: BorderPath, _ a: Double, _ b: Double, _ lineWidth: Double, _ cap: ProgressStrokeCap, _ paint: ProgressPaint) {
        if b > 1 {
            strokeAlong(path, a, 1, lineWidth, cap, paint)
            strokeAlong(path, 0, b - 1, lineWidth, cap, paint)
            return
        }
        let from = a * path.total
        let to = b * path.total
        guard to - from >= 0.3 else { return }
        func at(_ d: Double) -> (Double, Double, Int) {
            var i = 1
            while i < path.lengths.count - 1 && path.lengths[i] < d { i += 1 }
            let f = (d - path.lengths[i - 1]) / max(1e-6, path.lengths[i] - path.lengths[i - 1])
            let x0 = path.points[2 * i - 2]
            let y0 = path.points[2 * i - 1]
            return (x0 + (path.points[2 * i] - x0) * f, y0 + (path.points[2 * i + 1] - y0) * f, i)
        }
        let (sx, sy, si) = at(from)
        let (ex, ey, ei) = at(to)
        var result = [sx, sy]
        if si < ei {
            for i in si..<ei {
                result.append(path.points[2 * i])
                result.append(path.points[2 * i + 1])
            }
        }
        result.append(ex)
        result.append(ey)
        out.append(.polyline(points: result, closed: false, lineWidth: lineWidth, cap: cap, paint: paint))
    }

    mutating func border(_ w: Double, _ h: Double) {
        let t = p.thickness
        guard w > t, h > t else { return }
        let path = borderPath(w, h, t / 2, p.cornerRadius - t / 2)
        out.append(.polyline(points: Array(path.points.dropLast(2)), closed: true, lineWidth: t, cap: .butt, paint: solid(.track)))
        if s.indeterminate {
            let (a0, a1) = circularArc(s.indeterminateTime)
            let from = mod(a0 / tau, 1)
            strokeAlong(path, from, from + (a1 - a0) / tau, t, p.strokeCap, solid(.color))
        } else {
            let v = clamp01(s.value)
            if v > 0.0005 { strokeAlong(path, 0, v, t, p.strokeCap, solid(.color)) }
        }
    }

    // MARK: bars, grid, battery

    mutating func bars(_ w: Double, _ h: Double) {
        let n = p.segments
        let count = Double(n)
        let gap = max(3, p.trackGap)
        let width = (w - gap * (count - 1)) / count
        guard width > 0 else { return }
        let radius = p.strokeCap == .round ? min(width * 0.3, 4) : 0
        let center = mod(s.indeterminateTime / 1.4, 1) * (count + 3) - 1.5
        for i in 0..<n {
            let height = h * (0.25 + 0.75 * Double(i + 1) / count)
            let x = Double(i) * (width + gap)
            let y = h - height
            rect(x, y, width, height, radius, solid(.track))
            let fill = s.indeterminate ? bump(Double(i) + 0.5 - center, 1.6) : clamp01(clamp01(s.value) * count - Double(i))
            if fill <= 0.001 { continue }
            let inner = nested { $0.rect(x, h - height * fill, width, height * fill, 0, solid(.color)) }
            out.append(.clip(shape: rectClip(x, y, width, height, radius), commands: inner))
        }
    }

    mutating func grid(_ size: Double) {
        let k = p.segments
        let count = Double(k)
        let gap = max(2, p.trackGap * 0.75)
        let cell = (size - gap * (count - 1)) / count
        guard cell > 0 else { return }
        let radius = p.strokeCap == .round ? cell * 0.28 : cell * 0.08
        let rank = ProgressGeometry.gridOrder(k)
        let center = mod(s.indeterminateTime / 1.6, 1) * (2 * count + 1) - 1.5
        for r in 0..<k {
            for c in 0..<k {
                let x = Double(c) * (cell + gap)
                let y = Double(r) * (cell + gap)
                rect(x, y, cell, cell, radius, solid(.track))
                let fill = s.indeterminate
                    ? bump(Double(r + c) - center, 1.8)
                    : clamp01(clamp01(s.value) * count * count - Double(rank[r * k + c]))
                if fill <= 0.01 { continue }
                let side = cell * (0.3 + 0.7 * fill)
                rect(x + (cell - side) / 2, y + (cell - side) / 2, side, side, radius * side / cell, solid(.color, min(1, fill * 1.6)))
            }
        }
    }

    mutating func battery(_ w: Double, _ h: Double) {
        let border = max(1.5, p.thickness * 0.5)
        let capWidth = max(3, w * 0.07)
        let bodyWidth = w - capWidth - border * 0.5
        let radius = h * 0.24
        if bodyWidth - border > 0 && h - border > 0 {
            out.append(.strokeRect(
                x: border / 2,
                y: border / 2,
                width: bodyWidth - border,
                height: h - border,
                radius: max(0, min(radius, (bodyWidth - border) / 2, (h - border) / 2)),
                lineWidth: border,
                paint: solid(.color, 0.7)
            ))
        }
        rect(bodyWidth + border * 0.2, h * 0.34, w - bodyWidth - border * 0.2, h * 0.32, capWidth * 0.5, solid(.color, 0.7))
        let pad = border + max(1.5, p.trackGap * 0.5)
        let iw = bodyWidth - 2 * pad
        let ih = h - 2 * pad
        guard iw > 0, ih > 0 else { return }
        let filled: Double
        var alpha = 1.0
        if s.indeterminate {
            let u = mod(s.indeterminateTime / 1.8, 1)
            filled = iw * easeInOut(clamp01(u / 0.8))
            if u > 0.8 { alpha = 1 - (u - 0.8) / 0.2 }
        } else {
            filled = iw * clamp01(s.value)
        }
        let p = self.p
        let s = self.s
        let content = nested { b in
            b.rect(pad, pad, iw, ih, 0, solid(.track))
            b.rect(pad, pad, filled, ih, 0, solid(.color, alpha))
            if p.showLabel && !s.indeterminate {
                b.invertedLabel(ProgressGeometry.label(s.value), pad + iw / 2, pad + ih / 2, max(10, min(ih * 0.55, 30)), rectClip(pad, pad, filled, ih, 0))
            }
        }
        out.append(.clip(shape: rectClip(pad, pad, iw, ih, max(1, radius - pad * 0.7)), commands: content))
        if s.indeterminate {
            let bx = pad + iw / 2
            let by = pad + ih / 2
            let k = ih * 0.42
            var points: [Double] = []
            var i = 0
            while i < bolt.count {
                points.append(bx + bolt[i] * k * 0.9)
                points.append(by + bolt[i + 1] * k)
                i += 2
            }
            out.append(.polygon(points: points, paint: solid(.white)))
            out.append(.polyline(points: points, closed: true, lineWidth: 1.2, cap: .butt, paint: solid(.color)))
        }
    }
}
