import Foundation

private func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }

/// Updates closer together than this, in seconds, count as one stream whose rhythm the glide follows.
private let rhythmGap = 1.5
private let backwardDuration = 0.4
private let isolatedDuration = 0.5
private let waveStiffness = 120.0

/// Moves the displayed value to each new value along a cubic Hermite curve. Its duration follows the
/// rhythm of the updates, and both end slopes stay within three times the average slope, which keeps
/// the curve monotone: the displayed value never passes the real one.
private struct Glide {
    var value: Double
    var target: Double
    var velocity = 0.0
    var lastAt: Double?
    var active = false
    private var interval = isolatedDuration
    private var from = 0.0
    private var to = 0.0
    private var duration = 0.0
    private var startVelocity = 0.0
    private var endVelocity = 0.0
    private var elapsed = 0.0

    init(_ value: Double) {
        self.value = value
        target = value
    }

    mutating func jump(_ value: Double) {
        self.value = value
        target = value
        velocity = 0
        active = false
    }

    mutating func move(to target: Double, now: Double, smooth: Bool) {
        let gap = lastAt.map { now - $0 } ?? .infinity
        lastAt = now
        guard smooth else {
            jump(target)
            return
        }
        let rhythmic = gap >= 0 && gap < rhythmGap
        interval = rhythmic ? interval * 0.5 + max(0.05, gap) * 0.5 : isolatedDuration
        self.target = target
        let distance = target - value
        if abs(distance) < 1e-5 {
            jump(target)
            return
        }
        if distance < 0 {
            duration = backwardDuration
            startVelocity = 0
            endVelocity = 0
        } else {
            duration = rhythmic ? min(1, max(0.25, interval * 1.15)) : isolatedDuration
            let slope = distance / duration
            startVelocity = min(2.5 * slope, max(0, velocity))
            endVelocity = rhythmic && target < 1 ? 0.5 * slope : 0
        }
        from = value
        to = target
        elapsed = 0
        active = true
    }

    mutating func step(_ dt: Double) {
        guard active else { return }
        elapsed += dt
        let T = duration
        let u = elapsed >= T - 1e-9 ? 1 : elapsed / T
        let u2 = u * u
        let u3 = u2 * u
        let m0 = T * startVelocity
        let m1 = T * endVelocity
        value = (2 * u3 - 3 * u2 + 1) * from + (u3 - 2 * u2 + u) * m0 + (-2 * u3 + 3 * u2) * to + (u3 - u2) * m1
        velocity = ((6 * u2 - 6 * u) * from + (3 * u2 - 4 * u + 1) * m0 + (-6 * u2 + 6 * u) * to + (3 * u2 - 2 * u) * m1) / T
        if u >= 1 { jump(to) }
    }
}

/// The animation state of one progress indicator: the displayed value and buffer, the wave amplitude
/// and the clocks. Call `setValue` and `setBuffer` when the inputs change, `step` once per frame, and
/// draw `state`.
public final class ProgressAnimator {
    private var glide: Glide
    private var bufferGlide: Glide
    private var isIndeterminate: Bool
    private var wave: Double = 0
    private var waveVelocity = 0.0
    private var time = 0.0
    private var indeterminateTime = 0.0

    /// A nil or NaN value is indeterminate.
    public init(value: Double? = nil, buffer: Double? = nil) {
        let determinate = value.map { !$0.isNaN } ?? false
        isIndeterminate = !determinate
        glide = Glide(determinate ? clamp01(value!) : 0)
        bufferGlide = Glide(buffer.map { $0.isNaN ? 0 : clamp01($0) } ?? 0)
        wave = waveTarget
    }

    /// The value the indicator is moving to; nil while indeterminate.
    public var target: Double? { isIndeterminate ? nil : glide.target }

    public var indeterminate: Bool { isIndeterminate }

    /// True while the displayed value, the buffer or the wave amplitude are still moving.
    public var moving: Bool { glide.active || bufferGlide.active || wave != waveTarget || waveVelocity != 0 }

    /// Sets the real value; nil or NaN switches to indeterminate. `now` is a clock in seconds, used
    /// to measure the rhythm of updates. Leaving the indeterminate state starts again from 0.
    public func setValue(_ value: Double?, now: Double, smooth: Bool) {
        guard let value, !value.isNaN else {
            if !isIndeterminate { glide.jump(0) }
            isIndeterminate = true
            return
        }
        let target = clamp01(value)
        if isIndeterminate {
            isIndeterminate = false
            glide.jump(0)
            glide.lastAt = nil
        }
        if target == glide.target && (glide.active || glide.value == target) { return }
        glide.move(to: target, now: now, smooth: smooth)
    }

    /// Sets the buffer of linear `flat` and `wavy`; nil or NaN removes it.
    public func setBuffer(_ buffer: Double?, now: Double, smooth: Bool) {
        let target = buffer.map { $0.isNaN ? 0 : clamp01($0) } ?? 0
        if target == bufferGlide.target && (bufferGlide.active || bufferGlide.value == target) { return }
        bufferGlide.move(to: target, now: now, smooth: smooth)
    }

    /// Advances by `dt` seconds. A zero, negative or non-finite `speed` pauses the indeterminate
    /// animation. With `reduceMotion` the value and the wave jump to their targets, ambient motion
    /// stops and the indeterminate animation runs at half speed.
    public func step(_ dt: Double, speed: Double, reduceMotion: Bool) {
        guard dt > 0, dt.isFinite else { return }
        if reduceMotion {
            glide.jump(glide.target)
            bufferGlide.jump(bufferGlide.target)
        } else {
            if !isIndeterminate { glide.step(dt) }
            bufferGlide.step(dt)
            time += dt
        }
        if speed.isFinite && speed > 0 { indeterminateTime += dt * speed * (reduceMotion ? 0.5 : 1) }
        let target = waveTarget
        if reduceMotion {
            wave = target
            waveVelocity = 0
        } else {
            // The exact solution of a critically damped spring, so long frames cannot make it diverge.
            let omega = waveStiffness.squareRoot()
            let offset = wave - target
            let decay = exp(-omega * dt)
            let drift = (waveVelocity + omega * offset) * dt
            waveVelocity = (waveVelocity - omega * drift) * decay
            wave = min(1.2, max(0, target + (offset + drift) * decay))
            if abs(wave - target) < 1e-4 && abs(waveVelocity) < 1e-3 {
                wave = target
                waveVelocity = 0
            }
        }
    }

    public var state: ProgressState {
        ProgressState(
            indeterminate: isIndeterminate,
            value: isIndeterminate ? 0 : glide.value,
            buffer: bufferGlide.value,
            wave: wave,
            time: time,
            indeterminateTime: indeterminateTime
        )
    }

    /// The wave flattens near 0% and 100%, like Material 3 Expressive.
    private var waveTarget: Double {
        isIndeterminate || (glide.target > 0.1 && glide.target < 0.95) ? 1 : 0
    }
}
