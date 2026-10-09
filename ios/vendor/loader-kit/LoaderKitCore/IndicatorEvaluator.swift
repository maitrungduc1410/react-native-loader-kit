import Foundation

/// The state of one element at one point in time (`SPEC.md` §5.4).
public struct ElementState: Hashable, Sendable, Codable {
    /// Index across every part, which picks the element color.
    public var index: Int
    /// Index of the part the element belongs to.
    public var part: Int
    /// Element center, before translation.
    public var cx: Double
    public var cy: Double
    public var width: Double
    public var height: Double
    /// Combined scale: `scale * scaleX` and `scale * scaleY`.
    public var scaleX: Double
    public var scaleY: Double
    /// Element opacity times group opacity.
    public var opacity: Double
    /// The layout rotation (ring `orient`) plus the `rotate` track.
    public var rotate: Double
    public var rotateX: Double
    public var rotateY: Double
    public var translateX: Double
    public var translateY: Double
    /// Drawn part of each arc of a `ring`, as fractions of the arc. Nothing is drawn when
    /// `strokeEnd <= strokeStart` once both are clamped to [0, 1].
    public var strokeStart: Double
    public var strokeEnd: Double
    /// Combined group scale: `scale * scaleX` and `scale * scaleY` of the group tracks.
    public var groupScaleX: Double
    public var groupScaleY: Double
    /// Group transform around the box center, applied after the element transform.
    public var groupRotate: Double
    public var groupTranslateX: Double
    public var groupTranslateY: Double

    public init(
        index: Int,
        part: Int = 0,
        cx: Double,
        cy: Double,
        width: Double,
        height: Double,
        scaleX: Double = 1,
        scaleY: Double = 1,
        opacity: Double = 1,
        rotate: Double = 0,
        rotateX: Double = 0,
        rotateY: Double = 0,
        translateX: Double = 0,
        translateY: Double = 0,
        strokeStart: Double = 0,
        strokeEnd: Double = 1,
        groupScaleX: Double = 1,
        groupScaleY: Double = 1,
        groupRotate: Double = 0,
        groupTranslateX: Double = 0,
        groupTranslateY: Double = 0
    ) {
        self.index = index
        self.part = part
        self.cx = cx
        self.cy = cy
        self.width = width
        self.height = height
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.opacity = opacity
        self.rotate = rotate
        self.rotateX = rotateX
        self.rotateY = rotateY
        self.translateX = translateX
        self.translateY = translateY
        self.strokeStart = strokeStart
        self.strokeEnd = strokeEnd
        self.groupScaleX = groupScaleX
        self.groupScaleY = groupScaleY
        self.groupRotate = groupRotate
        self.groupTranslateX = groupTranslateX
        self.groupTranslateY = groupTranslateY
    }
}

/// A spec with its params resolved: layout geometry, start offsets, durations and tracks as plain
/// numbers. Build it once, then sample it as often as needed.
public struct IndicatorEvaluator: Sendable {
    /// Geometry of one element from the layout.
    public struct Geometry: Hashable, Sendable {
        public var cx: Double
        public var cy: Double
        public var width: Double
        public var height: Double
        /// Rotation that comes from the layout (ring `orient`).
        public var rotate: Double

        public init(cx: Double, cy: Double, width: Double, height: Double, rotate: Double) {
            self.cx = cx
            self.cy = cy
            self.width = width
            self.height = height
            self.rotate = rotate
        }
    }

    /// The spec shape with its params resolved and its defaults filled in.
    public enum Shape: Hashable, Sendable {
        case circle(startAngle: Double, sweep: Double)
        case rect(cornerRadius: Double)
        case ring(strokeWidth: Double, startAngle: Double, sweep: Double, segments: Int)
        case triangle
        case line
    }

    /// A track with its params resolved and one easing per segment.
    public struct Track<AnimatedProperty: Hashable & Sendable>: Hashable, Sendable {
        public let property: AnimatedProperty
        public let keyTimes: [Double]
        public let values: [Double]
        /// `keyTimes.count - 1` entries.
        public let easings: [IndicatorSpec.Easing]

        /// Value at cycle progress `progress` in [0, 1) (`SPEC.md` §5.2).
        public func value(at progress: Double) -> Double {
            let last = keyTimes.count - 1
            if progress <= keyTimes[0] { return values[0] }
            if progress >= keyTimes[last] { return values[last] }

            var k = 0
            while k < last - 1 && progress >= keyTimes[k + 1] { k += 1 }
            let start = keyTimes[k]
            let end = keyTimes[k + 1]
            let u = end > start ? (progress - start) / (end - start) : 1
            return values[k] + (values[k + 1] - values[k]) * easings[k].ease(u)
        }
    }

    /// One part of the spec with its layout, offsets and durations resolved.
    public struct Part: Hashable, Sendable {
        public let shape: Shape
        /// Index across every part of the first element of this part.
        public let firstIndex: Int
        public let elements: [Geometry]
        /// Start offset of each element in seconds. A negative offset means the element is part way
        /// through its cycle at time 0.
        public let offsets: [Double]
        /// Cycle length of each element in seconds.
        public let durations: [Double]
        /// Cycle length of the group tracks in seconds.
        public let duration: Double
        public let tracks: [Track<IndicatorSpec.Property>]
        public let groupTracks: [Track<IndicatorSpec.GroupProperty>]
        fileprivate let restValues: PropertyValues

        /// Value of `property` when no track drives it, with the part `rest` applied.
        public func restValue(_ property: IndicatorSpec.Property) -> Double {
            restValues[property]
        }

        /// Whether elements rotate out of the screen plane, so perspective applies.
        public var hasDepth: Bool {
            tracks.contains { $0.property == .rotateX || $0.property == .rotateY }
                || restValue(.rotateX) != 0 || restValue(.rotateY) != 0
        }
    }

    /// Specs with more elements than this in total are rejected.
    public static let maximumElementCount = 10_000
    /// Specs with more ring arcs than this in total (element count × `segments`) are rejected.
    public static let maximumArcCount = 10_000

    public let spec: IndicatorSpec
    /// Spec defaults merged with the overrides.
    public let params: [String: Double]
    /// Length of one spec cycle in seconds, which `cycleProgress` refers to.
    public let duration: Double
    public let perspective: Double
    public let parts: [Part]

    /// Number of elements across every part.
    public var elementCount: Int {
        parts.reduce(0) { $0 + $1.elements.count }
    }

    /// Resolves `spec` with the param overrides. Throws `IndicatorSpecError` when the spec
    /// cannot be evaluated (unknown param, stagger or durations shorter than the layout,
    /// malformed track, too many elements).
    /// It does not run the full validation: call `IndicatorSpec.validate()` for that.
    public init(spec: IndicatorSpec, params overrides: [String: Double] = [:]) throws {
        let params = spec.resolvedParams(overrides)
        let isInline: Bool
        if case .inline = spec.body { isInline = true } else { isInline = false }
        let resolvers = spec.parts.indices.map { index in
            Resolver(params: params, prefix: isInline ? "" : "parts[\(index)].")
        }

        var elementCount = 0
        var arcCount = 0
        for (part, resolver) in zip(spec.parts, resolvers) {
            let count = try resolver.elementCount(part.layout)
            elementCount += count
            if case let .ring(_, _, _, segments) = try resolver.shape(part.shape) { arcCount += count * segments }
        }
        let maximumElementCount = IndicatorEvaluator.maximumElementCount
        guard elementCount <= maximumElementCount else {
            throw IndicatorSpecError(problems: [
                "the spec has \(elementCount) elements, the maximum is \(maximumElementCount)",
            ])
        }
        let maximumArcCount = IndicatorEvaluator.maximumArcCount
        guard arcCount <= maximumArcCount else {
            throw IndicatorSpecError(problems: [
                "the spec draws \(arcCount) ring arcs, the maximum is \(maximumArcCount)",
            ])
        }

        var parts: [Part] = []
        var firstIndex = 0
        for (part, resolver) in zip(spec.parts, resolvers) {
            let elements = try resolver.layout(part.layout)
            let shape = try resolver.shape(part.shape)
            let duration = isInline ? spec.duration : part.duration ?? spec.duration
            firstIndex += elements.count

            var rest = PropertyValues()
            for (property, value) in part.rest {
                rest[property] = try resolver.number(value)
            }

            parts.append(Part(
                shape: shape,
                firstIndex: firstIndex - elements.count,
                elements: elements,
                offsets: try resolver.offsets(part.stagger, count: elements.count),
                durations: try resolver.durations(part.durations, fallback: duration, count: elements.count),
                duration: duration,
                tracks: try part.tracks.enumerated().map { index, track in
                    try resolver.track(track, path: "tracks[\(index)]")
                },
                groupTracks: try part.groupTracks.enumerated().map { index, track in
                    try resolver.track(track, path: "groupTracks[\(index)]")
                },
                restValues: rest
            ))
        }

        self.spec = spec
        self.params = params
        self.duration = spec.duration
        self.perspective = spec.perspective ?? IndicatorSpec.defaultPerspective
        self.parts = parts
    }

    /// State of every element at spec time `time` (seconds since the start, already multiplied by
    /// the speed). An element whose start offset is still ahead shows the rest values.
    public func states(at time: Double) -> [ElementState] {
        parts.enumerated().flatMap { partIndex, part -> [ElementState] in
            var group = GroupValues()
            let groupProgress = cycle(time, part.duration)
            if groupProgress >= 0 {
                for track in part.groupTracks { group[track.property] = track.value(at: groupProgress) }
            }

            return part.elements.indices.map { index in
                let element = part.elements[index]
                var values = part.restValues
                let progress = cycle(time - part.offsets[index], part.durations[index])
                if progress >= 0 {
                    for track in part.tracks { values[track.property] = track.value(at: progress) }
                }
                return ElementState(
                    index: part.firstIndex + index,
                    part: partIndex,
                    cx: element.cx,
                    cy: element.cy,
                    width: element.width,
                    height: element.height,
                    scaleX: values.scale * values.scaleX,
                    scaleY: values.scale * values.scaleY,
                    opacity: values.opacity * group.opacity,
                    rotate: element.rotate + values.rotate,
                    rotateX: values.rotateX,
                    rotateY: values.rotateY,
                    translateX: values.translateX,
                    translateY: values.translateY,
                    strokeStart: values.strokeStart,
                    strokeEnd: values.strokeEnd,
                    groupScaleX: group.scale * group.scaleX,
                    groupScaleY: group.scale * group.scaleY,
                    groupRotate: group.rotate,
                    groupTranslateX: group.translateX,
                    groupTranslateY: group.translateY
                )
            }
        }
    }

    /// Spec time for a frozen `cycleProgress` in [0, 1] of the spec `duration` (`SPEC.md` §8). It
    /// skips whole spec cycles until every element has started.
    public func timeForCycleProgress(_ cycleProgress: Double) -> Double {
        let latest = parts.lazy.flatMap(\.offsets).reduce(0) { Swift.max($0, $1) }
        let warmup = (latest / duration).rounded(.up) * duration
        let clamped = Swift.min(1, Swift.max(0, cycleProgress))
        return warmup + clamped * duration
    }
}

/// Cycle progress in [0, 1) at `local` seconds after the start, or -1 before the start.
private func cycle(_ local: Double, _ duration: Double) -> Double {
    local < 0 ? -1 : local.truncatingRemainder(dividingBy: duration) / duration
}

/// Resolves the fields of one part, with error paths under `prefix`.
private struct Resolver {
    let params: [String: Double]
    let prefix: String

    func number(_ value: IndicatorSpec.Value) throws -> Double {
        switch value {
        case .number(let number):
            return number
        case .param(let name):
            guard let resolved = params[name] else {
                throw IndicatorSpecError(problems: ["Unknown param \"\(name)\""])
            }
            return resolved
        }
    }

    func number(_ value: IndicatorSpec.Value?, default fallback: Double) throws -> Double {
        try value.map(number) ?? fallback
    }

    /// Counts are rounded to the nearest integer and are at least 1.
    func count(_ value: IndicatorSpec.Value, _ field: String) throws -> Int {
        let path = prefix + field
        let raw = try number(value)
        guard raw.isFinite else { throw IndicatorSpecError(problems: ["\(path) must be finite"]) }
        let rounded = roundHalfUp(raw)
        let maximumCount = IndicatorEvaluator.maximumElementCount
        guard rounded <= Double(maximumCount) else {
            throw IndicatorSpecError(problems: ["\(path) must be at most \(maximumCount)"])
        }
        return Int(max(1, rounded))
    }

    /// Number of elements of `layout`, without building their geometry.
    func elementCount(_ layout: IndicatorSpec.Layout) throws -> Int {
        switch layout {
        case .single:
            return 1
        case let .stack(countValue, _, _, _, _, _), let .row(countValue, _, _, _), let .ring(countValue, _, _, _, _, _):
            return try count(countValue, "layout.count")
        case let .grid(columns, rows, _):
            return try count(columns, "layout.columns") * count(rows, "layout.rows")
        }
    }

    func layout(_ layout: IndicatorSpec.Layout) throws -> [IndicatorEvaluator.Geometry] {
        typealias Geometry = IndicatorEvaluator.Geometry
        switch layout {
        case let .single(size, width, height, x, y):
            return [try single(size: size, width: width, height: height, x: x, y: y)]

        case let .stack(countValue, size, width, height, x, y):
            let count = try count(countValue, "layout.count")
            let element = try single(size: size, width: width, height: height, x: x, y: y)
            return Array(repeating: element, count: count)

        case let .row(countValue, gapValue, itemWidth, itemHeight):
            let count = try count(countValue, "layout.count")
            let gap = try number(gapValue)
            let width = try number(itemWidth, default: (1 - gap * Double(count - 1)) / Double(count))
            let height = try number(itemHeight, default: width)
            let start = (1 - (Double(count) * width + Double(count - 1) * gap)) / 2
            return (0..<count).map { i in
                Geometry(cx: start + width / 2 + Double(i) * (width + gap), cy: 0.5, width: width, height: height, rotate: 0)
            }

        case let .grid(columnsValue, rowsValue, gapValue):
            let columns = try count(columnsValue, "layout.columns")
            let rows = try count(rowsValue, "layout.rows")
            let gap = try number(gapValue)
            let width = (1 - gap * Double(columns - 1)) / Double(columns)
            let height = (1 - gap * Double(rows - 1)) / Double(rows)
            return (0..<(columns * rows)).map { i in
                let column = i % columns
                let row = i / columns
                return Geometry(
                    cx: width / 2 + Double(column) * (width + gap),
                    cy: height / 2 + Double(row) * (height + gap),
                    width: width,
                    height: height,
                    rotate: 0
                )
            }

        case let .ring(countValue, itemSize, itemWidth, itemHeight, startAngle, orient):
            let count = try count(countValue, "layout.count")
            let size = try number(itemSize)
            let start = try number(startAngle, default: 0)
            let radius = 0.5 - size / 2
            let width = try number(itemWidth, default: size)
            let height = try number(itemHeight, default: size)
            return (0..<count).map { i in
                let angle = start + (Double(i) * 2 * Double.pi) / Double(count)
                return Geometry(
                    cx: 0.5 + radius * cos(angle),
                    cy: 0.5 + radius * sin(angle),
                    width: width,
                    height: height,
                    rotate: orient ? angle + Double.pi / 2 : 0
                )
            }
        }
    }

    private func single(
        size: IndicatorSpec.Value?,
        width: IndicatorSpec.Value?,
        height: IndicatorSpec.Value?,
        x: IndicatorSpec.Value?,
        y: IndicatorSpec.Value?
    ) throws -> IndicatorEvaluator.Geometry {
        let side = try number(size, default: 1)
        return IndicatorEvaluator.Geometry(
            cx: try number(x, default: 0.5),
            cy: try number(y, default: 0.5),
            width: try number(width, default: side),
            height: try number(height, default: side),
            rotate: 0
        )
    }

    func shape(_ shape: IndicatorSpec.Shape) throws -> IndicatorEvaluator.Shape {
        switch shape {
        case let .circle(startAngle, sweep):
            return .circle(
                startAngle: try number(startAngle, default: -Double.pi / 2),
                sweep: try number(sweep, default: 2 * Double.pi)
            )
        case .rect(let cornerRadius):
            return .rect(cornerRadius: try number(cornerRadius, default: 0))
        case let .ring(strokeWidth, startAngle, sweep, segments):
            return .ring(
                strokeWidth: try number(strokeWidth),
                startAngle: try number(startAngle, default: -Double.pi / 2),
                sweep: try number(sweep, default: 2 * Double.pi),
                segments: try segments.map { try count($0, "shape.segments") } ?? 1
            )
        case .triangle:
            return .triangle
        case .line:
            return .line
        }
    }

    func offsets(_ stagger: IndicatorSpec.Stagger?, count: Int) throws -> [Double] {
        switch stagger {
        case nil:
            return Array(repeating: 0, count: count)
        case let .each(each, start)?:
            return (0..<count).map { (start ?? 0) + each * Double($0) }
        case .offsets(let offsets)?:
            guard offsets.count >= count else {
                throw IndicatorSpecError(problems: [
                    "\(prefix)stagger has \(offsets.count) entries but the layout has \(count) elements",
                ])
            }
            return Array(offsets.prefix(count))
        }
    }

    func durations(_ durations: [Double]?, fallback: Double, count: Int) throws -> [Double] {
        guard let durations else { return Array(repeating: fallback, count: count) }
        guard durations.count >= count else {
            throw IndicatorSpecError(problems: [
                "\(prefix)durations has \(durations.count) entries but the layout has \(count) elements",
            ])
        }
        return Array(durations.prefix(count))
    }

    func track<AnimatedProperty>(
        _ track: IndicatorSpec.KeyframeTrack<AnimatedProperty>,
        path field: String
    ) throws -> IndicatorEvaluator.Track<AnimatedProperty> {
        let path = prefix + field
        let segments = track.keyTimes.count - 1
        guard segments >= 1 else {
            throw IndicatorSpecError(problems: ["\(path).keyTimes needs at least 2 entries"])
        }
        guard track.values.count == track.keyTimes.count else {
            throw IndicatorSpecError(problems: ["\(path).values must have the same length as keyTimes"])
        }
        let easings: [IndicatorSpec.Easing]
        switch track.easing {
        case nil:
            easings = Array(repeating: .linear, count: segments)
        case .uniform(let easing)?:
            easings = Array(repeating: easing, count: segments)
        case .perSegment(let list)?:
            guard list.count == segments else {
                throw IndicatorSpecError(problems: ["\(path).easing needs one entry per segment (\(segments))"])
            }
            easings = list
        }
        return IndicatorEvaluator.Track(
            property: track.property,
            keyTimes: track.keyTimes,
            values: try track.values.map(number),
            easings: easings
        )
    }
}

/// JavaScript `Math.round`: halves round toward positive infinity.
private func roundHalfUp(_ value: Double) -> Double {
    let floor = value.rounded(.down)
    return value - floor >= 0.5 ? floor + 1 : floor
}

private struct PropertyValues: Hashable, Sendable {
    var scale = 1.0
    var scaleX = 1.0
    var scaleY = 1.0
    var opacity = 1.0
    var rotate = 0.0
    var rotateX = 0.0
    var rotateY = 0.0
    var translateX = 0.0
    var translateY = 0.0
    var strokeStart = 0.0
    var strokeEnd = 1.0

    subscript(property: IndicatorSpec.Property) -> Double {
        get {
            switch property {
            case .scale: return scale
            case .scaleX: return scaleX
            case .scaleY: return scaleY
            case .opacity: return opacity
            case .rotate: return rotate
            case .rotateX: return rotateX
            case .rotateY: return rotateY
            case .translateX: return translateX
            case .translateY: return translateY
            case .strokeStart: return strokeStart
            case .strokeEnd: return strokeEnd
            }
        }
        set {
            switch property {
            case .scale: scale = newValue
            case .scaleX: scaleX = newValue
            case .scaleY: scaleY = newValue
            case .opacity: opacity = newValue
            case .rotate: rotate = newValue
            case .rotateX: rotateX = newValue
            case .rotateY: rotateY = newValue
            case .translateX: translateX = newValue
            case .translateY: translateY = newValue
            case .strokeStart: strokeStart = newValue
            case .strokeEnd: strokeEnd = newValue
            }
        }
    }
}

private struct GroupValues {
    var scale = 1.0
    var scaleX = 1.0
    var scaleY = 1.0
    var opacity = 1.0
    var rotate = 0.0
    var translateX = 0.0
    var translateY = 0.0

    subscript(property: IndicatorSpec.GroupProperty) -> Double {
        get {
            switch property {
            case .scale: return scale
            case .scaleX: return scaleX
            case .scaleY: return scaleY
            case .opacity: return opacity
            case .rotate: return rotate
            case .translateX: return translateX
            case .translateY: return translateY
            }
        }
        set {
            switch property {
            case .scale: scale = newValue
            case .scaleX: scaleX = newValue
            case .scaleY: scaleY = newValue
            case .opacity: opacity = newValue
            case .rotate: rotate = newValue
            case .translateX: translateX = newValue
            case .translateY: translateY = newValue
            }
        }
    }
}
