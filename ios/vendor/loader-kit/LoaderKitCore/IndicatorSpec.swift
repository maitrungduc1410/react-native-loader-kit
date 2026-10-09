import Foundation

/// An indicator described as data, schema version 1. See `SPEC.md` for the meaning of every field.
///
/// Lengths are fractions of the indicator box side, angles are radians (positive is clockwise on
/// screen, 0 points right) and times are seconds at speed 1.
///
/// Writing your own spec is experimental: until the schema is declared stable, a minor release may
/// change it. The built-in indicators are not affected.
public struct IndicatorSpec: Hashable, Sendable {
    public static let currentSchemaVersion = 1
    public static let defaultPerspective = 2.5

    public var schemaVersion: Int
    public var name: String
    /// Length of one cycle in seconds, at speed 1. `cycleProgress` freezes a point of this cycle.
    public var duration: Double
    /// Parameter defaults. Users can override them by name.
    public var params: [String: Double]
    /// Distance from the viewer to the box for 3D rotations, in box units. Default 2.5.
    public var perspective: Double?
    /// One group of elements written inline, or a list of parts drawn in order.
    public var body: Body

    /// The groups of elements, in drawing order. An inline spec has one.
    public var parts: [Part] {
        switch body {
        case .inline(let part): return [part]
        case .parts(let parts): return parts
        }
    }

    public init(
        schemaVersion: Int = IndicatorSpec.currentSchemaVersion,
        name: String,
        duration: Double,
        params: [String: Double] = [:],
        perspective: Double? = nil,
        body: Body
    ) {
        self.schemaVersion = schemaVersion
        self.name = name
        self.duration = duration
        self.params = params
        self.perspective = perspective
        self.body = body
    }

    /// A spec with one group of elements, written inline.
    public init(
        schemaVersion: Int = IndicatorSpec.currentSchemaVersion,
        name: String,
        duration: Double,
        params: [String: Double] = [:],
        layout: Layout,
        shape: Shape,
        stagger: Stagger? = nil,
        durations: [Double]? = nil,
        rest: [Property: Value] = [:],
        perspective: Double? = nil,
        tracks: [Track] = [],
        groupTracks: [GroupTrack] = []
    ) {
        self.init(
            schemaVersion: schemaVersion,
            name: name,
            duration: duration,
            params: params,
            perspective: perspective,
            body: .inline(Part(
                layout: layout,
                shape: shape,
                tracks: tracks,
                stagger: stagger,
                durations: durations,
                rest: rest,
                groupTracks: groupTracks
            ))
        )
    }

    /// A spec made of parts drawn in order. Element indices, and so colors, run across the parts.
    public init(
        schemaVersion: Int = IndicatorSpec.currentSchemaVersion,
        name: String,
        duration: Double,
        params: [String: Double] = [:],
        perspective: Double? = nil,
        parts: [Part]
    ) {
        self.init(
            schemaVersion: schemaVersion,
            name: name,
            duration: duration,
            params: params,
            perspective: perspective,
            body: .parts(parts)
        )
    }
}

extension IndicatorSpec {
    public enum Body: Hashable, Sendable {
        /// The group fields are written at the top level of the spec. The part `duration` is ignored:
        /// the group runs on the spec `duration`.
        case inline(Part)
        case parts([Part])
    }

    /// A group of elements that share a layout, a shape and tracks.
    public struct Part: Hashable, Sendable {
        public var layout: Layout
        public var shape: Shape
        /// Tracks applied to every element of the group.
        public var tracks: [Track]
        public var stagger: Stagger?
        /// Cycle length of this group in seconds. Default: the spec `duration`.
        public var duration: Double?
        /// Cycle length of each element, by index, overriding `duration`. Must cover every element.
        public var durations: [Double]?
        /// Values of properties that no track drives, also shown before an element starts.
        public var rest: [Property: Value]
        /// Tracks that move the whole group around the box center, on the group's cycle, without stagger.
        public var groupTracks: [GroupTrack]

        public init(
            layout: Layout,
            shape: Shape,
            tracks: [Track] = [],
            stagger: Stagger? = nil,
            duration: Double? = nil,
            durations: [Double]? = nil,
            rest: [Property: Value] = [:],
            groupTracks: [GroupTrack] = []
        ) {
            self.layout = layout
            self.shape = shape
            self.tracks = tracks
            self.stagger = stagger
            self.duration = duration
            self.durations = durations
            self.rest = rest
            self.groupTracks = groupTracks
        }
    }

    /// A number, or a reference to a spec parameter.
    public enum Value: Hashable, Sendable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
        case number(Double)
        case param(String)

        public init(floatLiteral value: Double) {
            self = .number(value)
        }

        public init(integerLiteral value: Int) {
            self = .number(Double(value))
        }
    }

    public enum Layout: Hashable, Sendable {
        /// One element of `width × height` (default `size`, itself default 1) centered at `(x, y)`
        /// (default 0.5).
        case single(size: Value? = nil, width: Value? = nil, height: Value? = nil, x: Value? = nil, y: Value? = nil)
        /// `count` elements like `single`, all at the same place.
        case stack(count: Value, size: Value? = nil, width: Value? = nil, height: Value? = nil, x: Value? = nil, y: Value? = nil)
        /// `count` elements side by side. Without `itemWidth` they fill the box; with it the row is
        /// centered. `itemHeight` defaults to the element width.
        case row(count: Value, gap: Value, itemWidth: Value? = nil, itemHeight: Value? = nil)
        /// Row-major grid.
        case grid(columns: Value, rows: Value, gap: Value)
        /// Elements on a circle of radius `0.5 - itemSize / 2`, the first one at `startAngle`, each of
        /// `itemWidth × itemHeight` (default `itemSize`). With `orient`, each element is rotated by its
        /// angle plus π/2.
        case ring(
            count: Value,
            itemSize: Value,
            itemWidth: Value? = nil,
            itemHeight: Value? = nil,
            startAngle: Value? = nil,
            orient: Bool = false
        )
    }

    public enum Shape: Hashable, Sendable {
        /// A filled ellipse. With `sweep` below 2π, the part of it between the arc from `startAngle`
        /// (default -π/2) and the chord that joins the arc ends.
        case circle(startAngle: Value? = nil, sweep: Value? = nil)
        /// `cornerRadius` is a fraction of the shorter side of the element.
        case rect(cornerRadius: Value? = nil)
        /// A stroked circle made of `segments` arcs (default 1) of `sweep` each (default 2π), the first
        /// one starting at `startAngle` (default -π/2). `strokeWidth` is a fraction of the shorter side.
        case ring(strokeWidth: Value, startAngle: Value? = nil, sweep: Value? = nil, segments: Value? = nil)
        case triangle
        case line
    }

    public enum Property: String, Hashable, Sendable, CaseIterable {
        case scale
        case scaleX
        case scaleY
        case opacity
        case rotate
        case rotateX
        case rotateY
        case translateX
        case translateY
        /// Start of the drawn part of each arc of a `ring`, as a fraction of the arc.
        case strokeStart
        /// End of the drawn part of each arc of a `ring`, as a fraction of the arc.
        case strokeEnd

        /// Value when no track drives the property and the part sets no `rest` value, and before an
        /// element starts.
        public var restValue: Double {
            switch self {
            case .scale, .scaleX, .scaleY, .opacity, .strokeEnd: return 1
            case .rotate, .rotateX, .rotateY, .translateX, .translateY, .strokeStart: return 0
            }
        }
    }

    /// Properties a group track can animate. They transform the whole group around the box center.
    public enum GroupProperty: String, Hashable, Sendable, CaseIterable {
        case scale
        case scaleX
        case scaleY
        case opacity
        case rotate
        case translateX
        case translateY

        /// Value when no group track drives the property.
        public var restValue: Double {
            switch self {
            case .scale, .scaleX, .scaleY, .opacity: return 1
            case .rotate, .translateX, .translateY: return 0
            }
        }
    }

    public enum TrackEasing: Hashable, Sendable {
        /// One easing for every segment.
        case uniform(Easing)
        /// One easing per segment (`keyTimes.count - 1` entries).
        case perSegment([Easing])
    }

    /// Keyframes of one property over a cycle.
    public struct KeyframeTrack<AnimatedProperty>: Hashable, Sendable
    where AnimatedProperty: RawRepresentable & Hashable & Sendable, AnimatedProperty.RawValue == String {
        public var property: AnimatedProperty
        /// Non-decreasing, within [0, 1], same length as `values`, at least 2 entries.
        public var keyTimes: [Double]
        public var values: [Value]
        /// Default linear.
        public var easing: TrackEasing?

        public init(property: AnimatedProperty, keyTimes: [Double], values: [Value], easing: TrackEasing? = nil) {
            self.property = property
            self.keyTimes = keyTimes
            self.values = values
            self.easing = easing
        }
    }

    public typealias Track = KeyframeTrack<Property>
    public typealias GroupTrack = KeyframeTrack<GroupProperty>

    public enum Stagger: Hashable, Sendable {
        /// Start offset in seconds of each element, by index. Must cover every element. A negative
        /// offset starts the element part way through its cycle.
        case offsets([Double])
        /// Element `i` starts at `start + each * i` seconds (`start` defaults to 0).
        case each(Double, start: Double? = nil)
    }
}

// MARK: - JSON

extension IndicatorSpec: Codable {
    /// Decodes and validates a spec. Throws `IndicatorSpecError` when the spec breaks a rule.
    public init(from decoder: Decoder) throws {
        try self.init(validating: SpecJSON(from: decoder))
    }

    public func encode(to encoder: Encoder) throws {
        try json.encode(to: encoder)
    }

    /// Parses and validates a JSON spec. Throws `IndicatorSpecError` listing every problem.
    public init(json: String) throws {
        try self.init(jsonData: Data(json.utf8))
    }

    /// Parses and validates a JSON spec. Throws `IndicatorSpecError` listing every problem.
    public init(jsonData: Data) throws {
        try self.init(validating: SpecJSON.parse(jsonData))
    }

    /// The spec as compact JSON with sorted keys.
    public func jsonString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }

    init(validating json: SpecJSON) throws {
        let problems = SpecValidator.validate(json)
        guard problems.isEmpty else { throw IndicatorSpecError(problems: problems) }
        self = try IndicatorSpec(validatedJSON: json)
        let evaluationProblems = self.evaluationProblems()
        guard evaluationProblems.isEmpty else { throw IndicatorSpecError(problems: evaluationProblems) }
    }
}

// MARK: - Validation

extension IndicatorSpec {
    /// Every problem found in a JSON spec; an empty list means it is a valid schema v1 spec.
    public static func validate(json: String) -> [String] {
        validate(jsonData: Data(json.utf8))
    }

    /// Every problem found in a JSON spec; an empty list means it is a valid schema v1 spec.
    public static func validate(jsonData: Data) -> [String] {
        do {
            _ = try IndicatorSpec(validating: SpecJSON.parse(jsonData))
            return []
        } catch {
            return IndicatorSpecError.problems(of: error)
        }
    }

    /// Every problem found in this spec; an empty list means it is valid.
    public func validationErrors() -> [String] {
        let problems = SpecValidator.validate(json)
        return problems.isEmpty ? evaluationProblems() : problems
    }

    /// Throws `IndicatorSpecError` listing every problem found in this spec.
    public func validate() throws {
        let problems = validationErrors()
        if !problems.isEmpty { throw IndicatorSpecError(problems: problems) }
    }

    private func evaluationProblems() -> [String] {
        do {
            _ = try IndicatorEvaluator(spec: self)
            return []
        } catch {
            return IndicatorSpecError.problems(of: error)
        }
    }
}

// MARK: - Evaluation

extension IndicatorSpec {
    /// Spec defaults merged with the overrides. Overrides for unknown names are ignored.
    public func resolvedParams(_ overrides: [String: Double] = [:]) -> [String: Double] {
        var resolved = params
        for (name, value) in overrides where resolved[name] != nil {
            resolved[name] = value
        }
        return resolved
    }

    /// State of every element at spec time `time`. For repeated sampling, build an
    /// `IndicatorEvaluator` once instead.
    public func evaluate(at time: Double, params overrides: [String: Double] = [:]) throws -> [ElementState] {
        try IndicatorEvaluator(spec: self, params: overrides).states(at: time)
    }

    /// Spec time of a frozen `cycleProgress` in [0, 1] of the spec `duration`, after every element
    /// has started. It is a point of the animation cycle, not the progress of a task.
    public func timeForCycleProgress(_ cycleProgress: Double, params overrides: [String: Double] = [:]) throws -> Double {
        try IndicatorEvaluator(spec: self, params: overrides).timeForCycleProgress(cycleProgress)
    }
}

// MARK: - Built-in indicators

extension IndicatorSpec {
    /// Names of the built-in indicators.
    public static var builtinNames: [String] {
        BuiltinIndicatorSpecs.names
    }

    /// The built-in indicator called `name`, or `nil` when there is none.
    public static func builtin(named name: String) -> IndicatorSpec? {
        builtins[name]
    }

    private static let builtins: [String: IndicatorSpec] = BuiltinIndicatorSpecs.json.compactMapValues {
        try? IndicatorSpec(json: $0)
    }
}
