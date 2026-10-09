extension IndicatorSpec {
    /// A named easing (Core Animation control points) or a cubic bezier `(x1, y1, x2, y2)`.
    public enum Easing: Hashable, Sendable {
        case linear
        case ease
        case easeIn
        case easeOut
        case easeInOut
        /// `x1` and `x2` must be within [0, 1]; `y1` and `y2` can overshoot.
        case cubicBezier(x1: Double, y1: Double, x2: Double, y2: Double)

        public init?(name: String) {
            switch name {
            case "linear": self = .linear
            case "ease": self = .ease
            case "easeIn": self = .easeIn
            case "easeOut": self = .easeOut
            case "easeInOut": self = .easeInOut
            default: return nil
            }
        }

        /// The spec name of a named easing, `nil` for a cubic bezier.
        public var name: String? {
            switch self {
            case .linear: return "linear"
            case .ease: return "ease"
            case .easeIn: return "easeIn"
            case .easeOut: return "easeOut"
            case .easeInOut: return "easeInOut"
            case .cubicBezier: return nil
            }
        }

        public var controlPoints: (x1: Double, y1: Double, x2: Double, y2: Double) {
            switch self {
            case .linear: return (0, 0, 1, 1)
            case .ease: return (0.25, 0.1, 0.25, 1)
            case .easeIn: return (0.42, 0, 1, 1)
            case .easeOut: return (0, 0, 0.58, 1)
            case .easeInOut: return (0.42, 0, 0.58, 1)
            case let .cubicBezier(x1, y1, x2, y2): return (x1, y1, x2, y2)
            }
        }

        /// Eased progress for `x` in [0, 1], with the reference algorithm of `SPEC.md` §5.3.
        public func ease(_ x: Double) -> Double {
            let points = controlPoints
            return cubicBezierEase(x1: points.x1, y1: points.y1, x2: points.x2, y2: points.y2, x: x)
        }
    }
}

private let bezierEpsilon = 1e-7

func cubicBezierEase(x1: Double, y1: Double, x2: Double, y2: Double, x: Double) -> Double {
    if x <= 0 { return 0 }
    if x >= 1 { return 1 }
    if x1 == y1 && x2 == y2 { return x }

    let cx = 3 * x1
    let bx = 3 * (x2 - x1) - cx
    let ax = 1 - cx - bx
    let cy = 3 * y1
    let by = 3 * (y2 - y1) - cy
    let ay = 1 - cy - by
    func sampleX(_ t: Double) -> Double { ((ax * t + bx) * t + cx) * t }
    func sampleY(_ t: Double) -> Double { ((ay * t + by) * t + cy) * t }
    func slopeX(_ t: Double) -> Double { (3 * ax * t + 2 * bx) * t + cx }

    var t = x
    for _ in 0..<8 {
        let error = sampleX(t) - x
        if abs(error) < bezierEpsilon { return sampleY(t) }
        let slope = slopeX(t)
        if abs(slope) < bezierEpsilon { break }
        t -= error / slope
    }

    var lo = 0.0
    var hi = 1.0
    t = x
    for _ in 0..<50 {
        let value = sampleX(t)
        if abs(value - x) < bezierEpsilon { break }
        if value < x {
            lo = t
        } else {
            hi = t
        }
        t = (lo + hi) / 2
    }
    return sampleY(t)
}
