#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
#if canImport(LoaderKitCore)
import LoaderKitCore
#endif

#if canImport(UIKit) || canImport(AppKit)
/// Draws a `ProgressDrawing` into a Core Graphics context whose y axis points down, as in
/// `UIView.draw(_:)` and in a flipped `NSView`. The context must be the current one, for text.
struct ProgressRenderer {
    /// Opacity of the track when no track color is set.
    static let defaultTrackAlpha: CGFloat = 0.24
    /// Wedges per turn that stand in for a conic gradient, which Core Graphics only has from iOS 17
    /// and macOS 14.
    static let conicSteps = 180

    var color: CGColor
    /// `nil` draws the track in `color` at 24% opacity.
    var trackColor: CGColor?
    var labelColor: CGColor

    func draw(_ drawing: ProgressDrawing, in context: CGContext, origin: CGPoint) {
        context.saveGState()
        context.translateBy(x: origin.x + CGFloat(drawing.x), y: origin.y + CGFloat(drawing.y))
        draw(drawing.commands, in: context)
        context.restoreGState()
    }

    private func role(_ role: ProgressColorRole, _ alpha: Double) -> CGColor {
        var factor = CGFloat(alpha)
        let base: CGColor
        switch role {
        case .color:
            base = color
        case .track:
            if let trackColor {
                base = trackColor
            } else {
                base = color
                factor *= Self.defaultTrackAlpha
            }
        case .label:
            base = labelColor
        case .white:
            base = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        }
        if factor >= 1 { return base }
        return base.copy(alpha: base.alpha * max(0, factor)) ?? base
    }

    private func gradient(_ stops: [ProgressColorStop]) -> CGGradient? {
        var last: CGFloat = 0
        let locations = stops.map { stop -> CGFloat in
            last = max(last, min(1, max(0, CGFloat(stop.offset))))
            return last
        }
        let colors = stops.map { role($0.color, $0.alpha) } as CFArray
        return CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: locations)
    }

    /// Fills the current clip with `paint`. Gradients need the shape as a clip, so every fill and
    /// stroke goes through here.
    private func paintClip(_ paint: ProgressPaint, in context: CGContext) {
        switch paint {
        case let .solid(color, alpha):
            context.setFillColor(role(color, alpha))
            context.fill(context.boundingBoxOfClipPath)
        case let .linear(x0, y0, x1, y1, stops):
            guard let gradient = gradient(stops) else { return }
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: x0, y: y0),
                end: CGPoint(x: x1, y: y1),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        case let .radial(cx, cy, r, stops):
            guard let gradient = gradient(stops) else { return }
            let center = CGPoint(x: cx, y: cy)
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: CGFloat(max(1e-3, r)),
                options: [.drawsAfterEndLocation]
            )
        case let .conic(cx, cy, start, stops):
            fillConic(cx: cx, cy: cy, start: start, stops: stops, in: context)
        }
    }

    /// Wedges from the center past the corners of the clip, each in the color of its middle.
    private func fillConic(cx: Double, cy: Double, start: Double, stops: [ProgressColorStop], in context: CGContext) {
        let bounds = context.boundingBoxOfClipPath
        guard !bounds.isNull, !bounds.isEmpty else { return }
        var reach = 0.0
        for x in [bounds.minX, bounds.maxX] {
            for y in [bounds.minY, bounds.maxY] {
                reach = max(reach, hypot(Double(x) - cx, Double(y) - cy))
            }
        }
        let r = reach + 1
        let step = 2 * Double.pi / Double(Self.conicSteps)
        let colors = stops.map { srgbComponents(role($0.color, $0.alpha)) }
        context.saveGState()
        // Aliased wedges meet without seams or double-blended edges; the clip keeps the outline smooth.
        context.setShouldAntialias(false)
        for i in 0..<Self.conicSteps {
            let from = start + Double(i) * step
            let to = start + Double(i + 1) * step
            context.move(to: CGPoint(x: cx, y: cy))
            context.addLine(to: CGPoint(x: cx + r * cos(from), y: cy + r * sin(from)))
            context.addLine(to: CGPoint(x: cx + r * cos(to), y: cy + r * sin(to)))
            context.closePath()
            context.setFillColor(conicColor(stops, colors, (Double(i) + 0.5) / Double(Self.conicSteps)))
            context.fillPath()
        }
        context.restoreGState()
    }

    /// The color at `t` of a turn, mixed in sRGB like the other platforms.
    private func conicColor(_ stops: [ProgressColorStop], _ colors: [[CGFloat]], _ t: Double) -> CGColor {
        guard let first = stops.first else { return CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0) }
        var mixed = colors[0]
        if t > first.offset {
            mixed = colors[colors.count - 1]
            for i in 1..<stops.count where t <= stops[i].offset {
                let span = stops[i].offset - stops[i - 1].offset
                let u = CGFloat(span > 0 ? (t - stops[i - 1].offset) / span : 1)
                mixed = zip(colors[i - 1], colors[i]).map { $0 + ($1 - $0) * u }
                break
            }
        }
        return CGColor(srgbRed: mixed[0], green: mixed[1], blue: mixed[2], alpha: mixed[3])
    }

    private func srgbComponents(_ color: CGColor) -> [CGFloat] {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let components = color.converted(to: space, intent: .defaultIntent, options: nil)?.components,
              components.count == 4
        else { return [0, 0, 0, 0] }
        return components
    }

    private func fill(_ path: CGPath, _ paint: ProgressPaint, in context: CGContext) {
        if case let .solid(color, alpha) = paint {
            context.addPath(path)
            context.setFillColor(role(color, alpha))
            context.fillPath()
            return
        }
        context.saveGState()
        context.addPath(path)
        context.clip()
        paintClip(paint, in: context)
        context.restoreGState()
    }

    private func stroke(_ path: CGPath, lineWidth: Double, cap: ProgressStrokeCap, _ paint: ProgressPaint, in context: CGContext) {
        let lineCap: CGLineCap = cap == .round ? .round : .butt
        if case let .solid(color, alpha) = paint {
            context.addPath(path)
            context.setLineWidth(CGFloat(lineWidth))
            context.setLineCap(lineCap)
            context.setLineJoin(.round)
            context.setStrokeColor(role(color, alpha))
            context.strokePath()
            return
        }
        let outline = path.copy(strokingWithWidth: CGFloat(lineWidth), lineCap: lineCap, lineJoin: .round, miterLimit: 10)
        fill(outline, paint, in: context)
    }

    private func polygon(_ points: [Double], closed: Bool) -> CGPath {
        let path = CGMutablePath()
        var i = 0
        while i + 1 < points.count {
            let point = CGPoint(x: points[i], y: points[i + 1])
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            i += 2
        }
        if closed { path.closeSubpath() }
        return path
    }

    private func roundedRect(x: Double, y: Double, width: Double, height: Double, radius: Double) -> CGPath {
        let rect = CGRect(x: x, y: y, width: max(0, width), height: max(0, height))
        let r = CGFloat(max(0, min(radius, min(width, height) / 2)))
        return CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)
    }

    private func arcPath(cx: Double, cy: Double, r: Double, start: Double, end: Double) -> CGPath {
        let path = CGMutablePath()
        // The context is flipped, so clockwise on screen is `clockwise: false` in Core Graphics terms.
        path.addArc(center: CGPoint(x: cx, y: cy), radius: CGFloat(r), startAngle: CGFloat(start), endAngle: CGFloat(end), clockwise: false)
        return path
    }

    private func draw(_ commands: [ProgressCommand], in context: CGContext) {
        for command in commands {
            switch command {
            case let .line(x0, y0, x1, y1, lineWidth, cap, paint):
                let path = CGMutablePath()
                path.move(to: CGPoint(x: x0, y: y0))
                path.addLine(to: CGPoint(x: x1, y: y1))
                stroke(path, lineWidth: lineWidth, cap: cap, paint, in: context)
            case let .arc(cx, cy, r, start, end, lineWidth, cap, paint):
                stroke(arcPath(cx: cx, cy: cy, r: r, start: start, end: end), lineWidth: lineWidth, cap: cap, paint, in: context)
            case let .polyline(points, closed, lineWidth, cap, paint):
                stroke(polygon(points, closed: closed), lineWidth: lineWidth, cap: cap, paint, in: context)
            case let .circle(cx, cy, r, paint):
                fill(CGPath(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r), transform: nil), paint, in: context)
            case let .rect(x, y, width, height, radius, paint):
                fill(roundedRect(x: x, y: y, width: width, height: height, radius: radius), paint, in: context)
            case let .strokeRect(x, y, width, height, radius, lineWidth, paint):
                stroke(roundedRect(x: x, y: y, width: width, height: height, radius: radius), lineWidth: lineWidth, cap: .butt, paint, in: context)
            case let .polygon(points, paint):
                fill(polygon(points, closed: true), paint, in: context)
            case let .sector(cx, cy, r, start, end, paint):
                let path: CGPath
                if end - start >= 2 * Double.pi {
                    path = CGPath(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r), transform: nil)
                } else {
                    let sector = CGMutablePath()
                    sector.move(to: CGPoint(x: cx, y: cy))
                    sector.addArc(center: CGPoint(x: cx, y: cy), radius: CGFloat(r), startAngle: CGFloat(start), endAngle: CGFloat(end), clockwise: false)
                    sector.closeSubpath()
                    path = sector
                }
                fill(path, paint, in: context)
            case let .text(x, y, size, text, alignRight, paint):
                drawText(text, x: x, y: y, size: size, alignRight: alignRight, paint: paint)
            case let .clip(shape, commands):
                context.saveGState()
                switch shape {
                case let .rect(x, y, width, height, radius):
                    context.addPath(roundedRect(x: x, y: y, width: width, height: height, radius: radius))
                case let .circle(cx, cy, r):
                    context.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
                case let .polygon(points):
                    context.addPath(polygon(points, closed: true))
                }
                context.clip()
                draw(commands, in: context)
                context.restoreGState()
            }
        }
    }

    private func drawText(_ text: String, x: Double, y: Double, size: Double, alignRight: Bool, paint: ProgressPaint) {
        let color: CGColor
        switch paint {
        case let .solid(role, alpha): color = self.role(role, alpha)
        default: color = labelColor
        }
        #if canImport(UIKit)
        let font = UIFont.systemFont(ofSize: CGFloat(size), weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor(cgColor: color)]
        #else
        let font = NSFont.systemFont(ofSize: CGFloat(size), weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(cgColor: color) ?? NSColor.labelColor]
        #endif
        let string = NSAttributedString(string: text, attributes: attributes)
        let width = string.size().width
        let left = alignRight ? CGFloat(x) - width : CGFloat(x) - width / 2
        // Center the space between the ascender and the descender on y, like a canvas `middle` baseline.
        let top = CGFloat(y) + (font.descender - font.ascender) / 2
        string.draw(at: CGPoint(x: left, y: top))
    }
}
#endif
