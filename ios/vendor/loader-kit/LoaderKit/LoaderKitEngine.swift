#if canImport(QuartzCore)
import Foundation
import QuartzCore
#if canImport(LoaderKitCore)
import LoaderKitCore
#endif

/// Renders an indicator spec with Core Animation, so animations run on the render server.
///
/// Each part is a chain of layers for its group transform (`SPEC.md` §6 step 7), read from the
/// inside out: `transform.scale.x`/`.y`, then `transform.scale`, then `transform.rotation.z`, then
/// the outer layer's position applies the box center plus the group translation. Its opacity reaches
/// every shape of the part without group compositing, so it multiplies each shape's alpha.
///
/// Inside it, each element is a chain of layers, one per step of §6 steps 1 to 6: a transform layer
/// scales by `scaleX`/`scaleY`, then transform layers apply `scale`, `rotateX`, `rotateY` and
/// `rotate`, the container projects with `m34 = -1 / (d·S)` and its position applies the element
/// center plus `translateX`/`translateY`. The innermost shape layers draw the shape, one per arc
/// of a ring, and carry `opacity`, `strokeStart` and `strokeEnd`. Rest values are the model values
/// of those layers. Every track maps 1:1 to one key path, so keyframes, per-segment easing, element
/// durations and stagger are handed to Core Animation as is.
///
/// The playback clock (`SPEC.md` §8) is the timing of `rootLayer`: its local time is the spec time
/// plus `timeOrigin`. Every animation's `beginTime` is `timeOrigin` plus the start offset; a
/// negative offset becomes a `timeOffset` instead, so the element is already part way through its
/// cycle at spec time 0.
@MainActor
final class LoaderKitEngine {
    let rootLayer = CALayer()

    private(set) var spec: IndicatorSpec?
    private(set) var params: [String: Double] = [:]
    private(set) var error: IndicatorSpecError?

    var palette: [CGColor] = [] {
        didSet { if palette != oldValue { applyColors() } }
    }

    var speed: Double = 1 {
        didSet { if speed != oldValue { updatePlayback() } }
    }

    var isAnimating = true {
        didSet { if isAnimating != oldValue { updatePlayback() } }
    }

    var hidesWhenStopped = true {
        didSet { if hidesWhenStopped != oldValue { applyTiming() } }
    }

    var cycleProgress: Double? {
        didSet {
            if cycleProgress?.isNaN == true { cycleProgress = nil }
            if cycleProgress != oldValue { updatePlayback() }
        }
    }

    var reducesMotion = false {
        didSet { if reducesMotion != oldValue { updatePlayback() } }
    }

    /// Core Animation replaces a `beginTime` of exactly 0 with the current time, so spec time 0
    /// must not map to layer time 0.
    private static let timeOrigin: CFTimeInterval = 1

    private var sourceError: IndicatorSpecError?
    private var evaluator: IndicatorEvaluator?
    private var groups: [CALayer] = []
    private var shapes: [ShapeLayer] = []
    private var animations: [Animation] = []
    private var needsRebuild = true
    private var layoutSize: CGSize = .zero
    private var contentsScale: CGFloat = 1

    private var clockTime: Double = 0
    private var clockAnchor: CFTimeInterval = 0
    private var clockSpeed: Double = 0
    private var clockRunning = false

    init() {
        #if os(macOS)
        rootLayer.isGeometryFlipped = true
        #endif
        updatePlayback(restart: true)
    }

    // MARK: Source

    func setSpec(_ spec: IndicatorSpec?, error: IndicatorSpecError? = nil) {
        if spec != nil, spec == self.spec { return }
        self.spec = spec
        sourceError = error
        resolve()
    }

    func setParams(_ params: [String: Double]) {
        guard params != self.params else { return }
        self.params = params
        resolve()
    }

    private func resolve() {
        evaluator = nil
        error = sourceError
        if let spec {
            do {
                try spec.validate()
                evaluator = try IndicatorEvaluator(spec: spec, params: params)
            } catch let specError as IndicatorSpecError {
                error = specError
            } catch {
                self.error = IndicatorSpecError(problems: [String(describing: error)])
            }
        }
        needsRebuild = true
        updatePlayback(restart: true)
    }

    // MARK: Layout

    /// Builds the layers when the spec, the params or the size changed. The clock keeps running
    /// across a rebuild.
    func layout(bounds: CGRect, contentsScale: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rootLayer.frame = bounds
        if needsRebuild || bounds.size != layoutSize {
            layoutSize = bounds.size
            self.contentsScale = contentsScale
            rebuild()
        } else if contentsScale != self.contentsScale {
            self.contentsScale = contentsScale
            for shape in shapes { shape.layer.contentsScale = contentsScale }
        }
        CATransaction.commit()
    }

    /// Adds the animations again, for when the system removed them (app in the background,
    /// layer detached from its window). The clock is untouched, so time does not jump.
    func restoreAnimations() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for item in animations { item.layer.add(item.animation, forKey: item.key) }
        CATransaction.commit()
    }

    private func rebuild() {
        needsRebuild = false
        for group in groups { group.removeFromSuperlayer() }
        groups = []
        shapes = []
        animations = []

        let side = Double(Swift.min(layoutSize.width, layoutSize.height))
        guard let evaluator, side.isFinite, side > 0 else { return }
        let box = Box(
            x: (Double(layoutSize.width) - side) / 2,
            y: (Double(layoutSize.height) - side) / 2,
            side: side
        )

        for part in evaluator.parts {
            let group = Group(box: box)
            groups.append(group.translation)
            rootLayer.addSublayer(group.translation)
            if part.duration.isFinite, part.duration > 0 {
                for track in part.groupTracks {
                    let target = group.target(of: track.property, box: box)
                    addAnimation(
                        to: [target.layer],
                        key: "group." + track.property.rawValue,
                        keyPath: target.keyPath,
                        track: track,
                        value: target.value,
                        duration: part.duration,
                        offset: 0
                    )
                }
            }

            for (index, geometry) in part.elements.enumerated() {
                let element = Element(
                    geometry: geometry,
                    part: part,
                    side: side,
                    perspective: evaluator.perspective,
                    contentsScale: contentsScale
                )
                group.content.addSublayer(element.container)
                let stroked: Bool
                if case .ring = part.shape { stroked = true } else { stroked = false }
                for layer in element.shapes {
                    shapes.append(ShapeLayer(layer: layer, index: part.firstIndex + index, stroked: stroked))
                }

                let duration = part.durations[index]
                let offset = part.offsets[index]
                guard duration.isFinite, duration > 0, offset.isFinite else { continue }
                for track in part.tracks {
                    let target = element.target(of: track.property, geometry: geometry, side: side)
                    addAnimation(
                        to: target.layers,
                        key: track.property.rawValue,
                        keyPath: target.keyPath,
                        track: track,
                        value: target.value,
                        duration: duration,
                        offset: offset
                    )
                }
            }
        }
        applyColors()
        restoreAnimations()
    }

    private func addAnimation<AnimatedProperty>(
        to layers: [CALayer],
        key: String,
        keyPath: String,
        track: IndicatorEvaluator.Track<AnimatedProperty>,
        value: (Double) -> Double,
        duration: Double,
        offset: Double
    ) {
        let animation = Self.keyframeAnimation(
            keyPath: keyPath,
            track: track,
            value: value,
            duration: duration,
            offset: offset
        )
        for layer in layers {
            animations.append(Animation(layer: layer, key: key, animation: animation))
        }
    }

    /// Core Animation needs keyTimes from 0 to 1, so a track that starts late or ends early is
    /// padded with its first or last value, which is what `SPEC.md` §5.2 samples there.
    private static func keyframeAnimation<AnimatedProperty>(
        keyPath: String,
        track: IndicatorEvaluator.Track<AnimatedProperty>,
        value: (Double) -> Double,
        duration: Double,
        offset: Double
    ) -> CAKeyframeAnimation {
        var keyTimes = track.keyTimes
        var values = track.values.map { sanitized(value($0)) }
        var timingFunctions = track.easings.map(timingFunction)
        if keyTimes[0] > 0 {
            keyTimes.insert(0, at: 0)
            values.insert(values[0], at: 0)
            timingFunctions.insert(CAMediaTimingFunction(name: .linear), at: 0)
        }
        if keyTimes[keyTimes.count - 1] < 1 {
            keyTimes.append(1)
            values.append(values[values.count - 1])
            timingFunctions.append(CAMediaTimingFunction(name: .linear))
        }

        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.keyTimes = keyTimes.map { NSNumber(value: $0) }
        animation.values = values.map { NSNumber(value: $0) }
        animation.timingFunctions = timingFunctions
        animation.calculationMode = .linear
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.beginTime = timeOrigin + Swift.max(0, offset)
        animation.timeOffset = Swift.max(0, -offset)
        animation.isRemovedOnCompletion = false
        return animation
    }

    private static func timingFunction(_ easing: IndicatorSpec.Easing) -> CAMediaTimingFunction {
        let points = easing.controlPoints
        return CAMediaTimingFunction(
            controlPoints: Float(points.x1.clamped(to: 0...1)),
            Float(points.y1),
            Float(points.x2.clamped(to: 0...1)),
            Float(points.y2)
        )
    }

    private func applyColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for shape in shapes {
            let color = palette.isEmpty ? nil : palette[shape.index % palette.count]
            shape.layer.fillColor = shape.stroked ? nil : color
            shape.layer.strokeColor = shape.stroked ? color : nil
        }
        CATransaction.commit()
    }

    // MARK: Playback

    /// Restarts the clock at spec time 0.
    func restartClock() {
        updatePlayback(restart: true)
    }

    private func parentTime() -> CFTimeInterval {
        let now = CACurrentMediaTime()
        return rootLayer.superlayer?.convertTime(now, from: nil) ?? now
    }

    private func updatePlayback(restart: Bool = false) {
        let now = parentTime()
        if restart {
            clockTime = 0
        } else if clockRunning {
            clockTime += (now - clockAnchor) * clockSpeed
        }
        clockAnchor = now
        clockSpeed = speed
        clockRunning = isAnimating && speed > 0 && speed.isFinite && cycleProgress == nil && !reducesMotion
        applyTiming()
    }

    private func frozenTime() -> Double? {
        let frozenCycleProgress: Double
        if let cycleProgress {
            frozenCycleProgress = cycleProgress
        } else if reducesMotion {
            frozenCycleProgress = 0
        } else {
            return nil
        }
        return evaluator?.timeForCycleProgress(frozenCycleProgress) ?? 0
    }

    private func applyTiming() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if let frozen = frozenTime() {
            rootLayer.speed = 0
            rootLayer.beginTime = 0
            rootLayer.timeOffset = Self.timeOrigin + sanitized(frozen)
        } else if clockRunning {
            rootLayer.speed = Float(clockSpeed)
            rootLayer.beginTime = clockAnchor
            rootLayer.timeOffset = Self.timeOrigin + clockTime
        } else {
            rootLayer.speed = 0
            rootLayer.beginTime = 0
            rootLayer.timeOffset = Self.timeOrigin + clockTime
        }
        rootLayer.isHidden = hidesWhenStopped && !isAnimating
        CATransaction.commit()
    }
}

/// The square the indicator is drawn in, in points (`SPEC.md` §1).
private struct Box {
    var x: Double
    var y: Double
    var side: Double
}

// MARK: - Layers

private struct Animation {
    let layer: CALayer
    let key: String
    let animation: CAAnimation
}

private struct ShapeLayer {
    let layer: CAShapeLayer
    /// Global element index, which picks the color.
    let index: Int
    let stroked: Bool
}

/// The group transform of one part: box-sized layers centered on the box.
@MainActor
private final class Group {
    let translation = CALayer()
    let rotation = CALayer()
    let scale = CALayer()
    let stretch = CALayer()
    /// Holds the element layers, in box coordinates.
    var content: CALayer { stretch }

    init(box: Box) {
        let bounds = CGRect(x: 0, y: 0, width: layerValue(box.side), height: layerValue(box.side))
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        var parent: CALayer?
        for layer in [translation, rotation, scale, stretch] {
            layer.bounds = bounds
            layer.position = center
            layer.allowsGroupOpacity = false
            parent?.addSublayer(layer)
            parent = layer
        }
        translation.position = CGPoint(x: layerValue(box.x + box.side / 2), y: layerValue(box.y + box.side / 2))
    }

    func target(
        of property: IndicatorSpec.GroupProperty,
        box: Box
    ) -> (layer: CALayer, keyPath: String, value: (Double) -> Double) {
        switch property {
        case .translateX:
            return (translation, "position.x", { box.x + (0.5 + $0) * box.side })
        case .translateY:
            return (translation, "position.y", { box.y + (0.5 + $0) * box.side })
        case .opacity:
            return (translation, "opacity", { $0 })
        case .rotate:
            return (rotation, "transform.rotation.z", { $0 })
        case .scale:
            return (scale, "transform.scale", { $0 })
        case .scaleX:
            return (stretch, "transform.scale.x", { $0 })
        case .scaleY:
            return (stretch, "transform.scale.y", { $0 })
        }
    }
}

@MainActor
private final class Element {
    let container = CALayer()
    let rotationZ = CATransformLayer()
    let rotationY = CATransformLayer()
    let rotationX = CATransformLayer()
    let scale = CATransformLayer()
    let stretch = CATransformLayer()
    private(set) var shapes: [CAShapeLayer] = []

    init(
        geometry: IndicatorEvaluator.Geometry,
        part: IndicatorEvaluator.Part,
        side: Double,
        perspective: Double,
        contentsScale: CGFloat
    ) {
        let size = CGSize(width: layerValue(geometry.width * side), height: layerValue(geometry.height * side))
        let bounds = CGRect(origin: .zero, size: size)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        container.bounds = bounds
        container.allowsGroupOpacity = false
        var parent: CALayer = container
        for layer in [rotationZ, rotationY, rotationX, scale, stretch] as [CALayer] {
            layer.bounds = bounds
            layer.position = center
            parent.addSublayer(layer)
            parent = layer
        }

        for path in Self.paths(part.shape, size: size) {
            let shape = CAShapeLayer()
            shape.bounds = bounds
            shape.position = center
            shape.contentsScale = contentsScale
            shape.path = path
            if case let .ring(strokeWidth, _, _, _) = part.shape {
                shape.lineWidth = Swift.max(0, layerValue(strokeWidth * Double(Swift.min(size.width, size.height))))
                shape.lineCap = .butt
                shape.strokeStart = layerValue(part.restValue(.strokeStart))
                shape.strokeEnd = layerValue(part.restValue(.strokeEnd))
            }
            shape.opacity = Float(sanitized(part.restValue(.opacity)))
            stretch.addSublayer(shape)
            shapes.append(shape)
        }

        container.position = CGPoint(
            x: layerValue((geometry.cx + part.restValue(.translateX)) * side),
            y: layerValue((geometry.cy + part.restValue(.translateY)) * side)
        )
        if part.hasDepth {
            var projection = CATransform3DIdentity
            projection.m34 = layerValue(-1 / (perspective * side))
            container.sublayerTransform = projection
        }
        rotationZ.transform = CATransform3DMakeRotation(layerValue(geometry.rotate + part.restValue(.rotate)), 0, 0, 1)
        rotationY.transform = CATransform3DMakeRotation(layerValue(part.restValue(.rotateY)), 0, 1, 0)
        rotationX.transform = CATransform3DMakeRotation(layerValue(part.restValue(.rotateX)), 1, 0, 0)
        let uniform = layerValue(part.restValue(.scale))
        scale.transform = CATransform3DMakeScale(uniform, uniform, 1)
        stretch.transform = CATransform3DMakeScale(
            layerValue(part.restValue(.scaleX)),
            layerValue(part.restValue(.scaleY)),
            1
        )
    }

    func target(
        of property: IndicatorSpec.Property,
        geometry: IndicatorEvaluator.Geometry,
        side: Double
    ) -> (layers: [CALayer], keyPath: String, value: (Double) -> Double) {
        switch property {
        case .translateX:
            return ([container], "position.x", { (geometry.cx + $0) * side })
        case .translateY:
            return ([container], "position.y", { (geometry.cy + $0) * side })
        case .rotate:
            return ([rotationZ], "transform.rotation.z", { geometry.rotate + $0 })
        case .rotateY:
            return ([rotationY], "transform.rotation.y", { $0 })
        case .rotateX:
            return ([rotationX], "transform.rotation.x", { $0 })
        case .scale:
            return ([scale], "transform.scale", { $0 })
        case .scaleX:
            return ([stretch], "transform.scale.x", { $0 })
        case .scaleY:
            return ([stretch], "transform.scale.y", { $0 })
        case .opacity:
            return (shapes, "opacity", { $0 })
        case .strokeStart:
            return (shapes, "strokeStart", { $0 })
        case .strokeEnd:
            return (shapes, "strokeEnd", { $0 })
        }
    }

    /// Shapes per `SPEC.md` §4, filling the element rectangle: one path per layer.
    private static func paths(_ kind: IndicatorEvaluator.Shape, size: CGSize) -> [CGPath] {
        let rect = CGRect(origin: .zero, size: size)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let shortSide = Double(Swift.min(size.width, size.height))
        switch kind {
        case let .circle(startAngle, sweep):
            let sweep = sanitized(sweep)
            if sweep >= 2 * Double.pi { return [CGPath(ellipseIn: rect, transform: nil)] }
            guard sweep > 0 else { return [] }
            let path = CGMutablePath()
            let ellipse = CGAffineTransform(a: center.x, b: 0, c: 0, d: center.y, tx: center.x, ty: center.y)
            path.addRelativeArc(
                center: .zero,
                radius: 1,
                startAngle: layerValue(startAngle),
                delta: CGFloat(sweep),
                transform: ellipse
            )
            path.closeSubpath()
            return [path]
        case .rect(let cornerRadius):
            return [roundedRect(rect, radius: layerValue(cornerRadius * shortSide))]
        case let .ring(strokeWidth, startAngle, sweep, segments):
            let stroke = sanitized(strokeWidth * shortSide)
            guard stroke > 0, stroke < shortSide else { return [] }
            let radius = CGFloat((shortSide - stroke) / 2)
            let delta = CGFloat(sanitized(sweep).clamped(to: 0...(2 * Double.pi)))
            return (0..<segments).map { k in
                let path = CGMutablePath()
                path.addRelativeArc(
                    center: center,
                    radius: radius,
                    startAngle: layerValue(startAngle + Double(k) * 2 * Double.pi / Double(segments)),
                    delta: delta
                )
                return path
            }
        case .triangle:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: size.width / 2, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
            return [path]
        case .line:
            return [roundedRect(rect, radius: CGFloat(shortSide / 2))]
        }
    }

    /// `CGPath(roundedRect:)` requires the radius to fit in half of each side.
    private static func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
        let limit = Swift.min(rect.width, rect.height) / 2
        let clamped = Swift.max(0, Swift.min(radius, limit))
        return CGPath(roundedRect: rect, cornerWidth: clamped, cornerHeight: clamped, transform: nil)
    }
}

/// Core Animation raises an exception on NaN geometry, which bad params can produce.
private func sanitized(_ value: Double) -> Double {
    value.isFinite ? value : 0
}

private func layerValue(_ value: Double) -> CGFloat {
    CGFloat(sanitized(value))
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
#endif
