import Foundation

/// Untyped JSON, so validation can report problems that a typed decoder would only fail on.
enum SpecJSON: Hashable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([SpecJSON])
    case object([String: SpecJSON])

    static func parse(_ data: Data) throws -> SpecJSON {
        do {
            return try JSONDecoder().decode(SpecJSON.self, from: data)
        } catch {
            throw IndicatorSpecError(problems: ["spec is not valid JSON"])
        }
    }

    subscript(key: String) -> SpecJSON? {
        if case .object(let object) = self { return object[key] }
        return nil
    }

    var number: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    var string: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var bool: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var array: [SpecJSON]? {
        if case .array(let value) = self { return value }
        return nil
    }

    var object: [String: SpecJSON]? {
        if case .object(let value) = self { return value }
        return nil
    }
}

extension SpecJSON: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([SpecJSON].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: SpecJSON].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
}

// MARK: - Typed model <-> JSON

private func malformed(_ path: String) -> IndicatorSpecError {
    IndicatorSpecError(problems: ["\(path) is malformed"])
}

private func number(_ json: SpecJSON, path: String) throws -> Double {
    guard let value = json.number else { throw malformed(path) }
    return value
}

extension IndicatorSpec {
    /// Builds the typed model from JSON that already passed `SpecValidator`.
    init(validatedJSON json: SpecJSON) throws {
        guard
            let version = json["schemaVersion"]?.number.flatMap({ Int(exactly: $0) }),
            let name = json["name"]?.string,
            let duration = json["duration"]?.number
        else { throw malformed("spec") }

        let body: Body
        if let parts = json["parts"] {
            guard let parts = parts.array else { throw malformed("parts") }
            body = .parts(try parts.enumerated().map { index, part in
                try Part(json: part, prefix: "parts[\(index)].", inline: false)
            })
        } else {
            body = .inline(try Part(json: json, prefix: "", inline: true))
        }

        self.init(
            schemaVersion: version,
            name: name,
            duration: duration,
            params: (json["params"]?.object ?? [:]).compactMapValues(\.number),
            perspective: json["perspective"]?.number,
            body: body
        )
    }

    var json: SpecJSON {
        var object: [String: SpecJSON] = [
            "schemaVersion": .number(Double(schemaVersion)),
            "name": .string(name),
            "duration": .number(duration),
        ]
        if !params.isEmpty { object["params"] = .object(params.mapValues(SpecJSON.number)) }
        object["perspective"] = perspective.map(SpecJSON.number)
        switch body {
        case .inline(let part):
            object.merge(part.fields(inline: true)) { current, _ in current }
        case .parts(let parts):
            object["parts"] = .array(parts.map { .object($0.fields(inline: false)) })
        }
        return .object(object)
    }
}

extension IndicatorSpec.Part {
    init(json: SpecJSON, prefix: String, inline: Bool) throws {
        let path = { (field: String) in prefix + field }
        self.init(
            layout: try IndicatorSpec.Layout(json: json["layout"], path: path("layout")),
            shape: try IndicatorSpec.Shape(json: json["shape"], path: path("shape")),
            tracks: try (json["tracks"]?.array ?? []).enumerated().map { index, track in
                try IndicatorSpec.Track(json: track, path: path("tracks[\(index)]"))
            },
            stagger: try json["stagger"].map { try IndicatorSpec.Stagger(json: $0, path: path("stagger")) },
            duration: inline ? nil : json["duration"]?.number,
            durations: try json["durations"]?.array.map { durations in
                try durations.map { try number($0, path: path("durations")) }
            },
            rest: try (json["rest"]?.object ?? [:]).reduce(into: [:]) { rest, entry in
                guard let property = IndicatorSpec.Property(rawValue: entry.key) else {
                    throw malformed(path("rest"))
                }
                rest[property] = try IndicatorSpec.Value(json: entry.value, path: path("rest.\(entry.key)"))
            },
            groupTracks: try (json["groupTracks"]?.array ?? []).enumerated().map { index, track in
                try IndicatorSpec.GroupTrack(json: track, path: path("groupTracks[\(index)]"))
            }
        )
    }

    func fields(inline: Bool) -> [String: SpecJSON] {
        var object: [String: SpecJSON] = ["layout": layout.json, "shape": shape.json]
        if !tracks.isEmpty { object["tracks"] = .array(tracks.map(\.json)) }
        object["stagger"] = stagger?.json
        if !inline { object["duration"] = duration.map(SpecJSON.number) }
        object["durations"] = durations.map { .array($0.map(SpecJSON.number)) }
        if !rest.isEmpty {
            object["rest"] = .object(Dictionary(uniqueKeysWithValues: rest.map { ($0.key.rawValue, $0.value.json) }))
        }
        if !groupTracks.isEmpty { object["groupTracks"] = .array(groupTracks.map(\.json)) }
        return object
    }
}

extension IndicatorSpec.Value {
    init(json: SpecJSON?, path: String) throws {
        if let number = json?.number {
            self = .number(number)
        } else if let name = json?["$param"]?.string {
            self = .param(name)
        } else {
            throw malformed(path)
        }
    }

    static func optional(_ json: SpecJSON?, path: String) throws -> Self? {
        guard let json else { return nil }
        return try Self(json: json, path: path)
    }

    var json: SpecJSON {
        switch self {
        case .number(let value): return .number(value)
        case .param(let name): return .object(["$param": .string(name)])
        }
    }
}

extension IndicatorSpec.Layout {
    init(json: SpecJSON?, path: String) throws {
        typealias Value = IndicatorSpec.Value
        func required(_ field: String) throws -> Value {
            try Value(json: json?[field], path: "\(path).\(field)")
        }
        func optional(_ field: String) throws -> Value? {
            try Value.optional(json?[field], path: "\(path).\(field)")
        }

        switch json?["type"]?.string {
        case "single":
            self = .single(
                size: try optional("size"),
                width: try optional("width"),
                height: try optional("height"),
                x: try optional("x"),
                y: try optional("y")
            )
        case "stack":
            self = .stack(
                count: try required("count"),
                size: try optional("size"),
                width: try optional("width"),
                height: try optional("height"),
                x: try optional("x"),
                y: try optional("y")
            )
        case "row":
            self = .row(
                count: try required("count"),
                gap: try required("gap"),
                itemWidth: try optional("itemWidth"),
                itemHeight: try optional("itemHeight")
            )
        case "grid":
            self = .grid(columns: try required("columns"), rows: try required("rows"), gap: try required("gap"))
        case "ring":
            self = .ring(
                count: try required("count"),
                itemSize: try required("itemSize"),
                itemWidth: try optional("itemWidth"),
                itemHeight: try optional("itemHeight"),
                startAngle: try optional("startAngle"),
                orient: json?["orient"]?.bool ?? false
            )
        default:
            throw malformed(path)
        }
    }

    var json: SpecJSON {
        var object: [String: SpecJSON]
        switch self {
        case let .single(size, width, height, x, y):
            object = ["type": .string("single")]
            object["size"] = size?.json
            object["width"] = width?.json
            object["height"] = height?.json
            object["x"] = x?.json
            object["y"] = y?.json
        case let .stack(count, size, width, height, x, y):
            object = ["type": .string("stack"), "count": count.json]
            object["size"] = size?.json
            object["width"] = width?.json
            object["height"] = height?.json
            object["x"] = x?.json
            object["y"] = y?.json
        case let .row(count, gap, itemWidth, itemHeight):
            object = ["type": .string("row"), "count": count.json, "gap": gap.json]
            object["itemWidth"] = itemWidth?.json
            object["itemHeight"] = itemHeight?.json
        case let .grid(columns, rows, gap):
            object = ["type": .string("grid"), "columns": columns.json, "rows": rows.json, "gap": gap.json]
        case let .ring(count, itemSize, itemWidth, itemHeight, startAngle, orient):
            object = ["type": .string("ring"), "count": count.json, "itemSize": itemSize.json]
            object["itemWidth"] = itemWidth?.json
            object["itemHeight"] = itemHeight?.json
            object["startAngle"] = startAngle?.json
            if orient { object["orient"] = .bool(true) }
        }
        return .object(object)
    }
}

extension IndicatorSpec.Shape {
    init(json: SpecJSON?, path: String) throws {
        func optional(_ field: String) throws -> IndicatorSpec.Value? {
            try .optional(json?[field], path: "\(path).\(field)")
        }

        switch json?["type"]?.string {
        case "circle":
            self = .circle(startAngle: try optional("startAngle"), sweep: try optional("sweep"))
        case "rect":
            self = .rect(cornerRadius: try optional("cornerRadius"))
        case "ring":
            self = .ring(
                strokeWidth: try IndicatorSpec.Value(json: json?["strokeWidth"], path: "\(path).strokeWidth"),
                startAngle: try optional("startAngle"),
                sweep: try optional("sweep"),
                segments: try optional("segments")
            )
        case "triangle":
            self = .triangle
        case "line":
            self = .line
        default:
            throw malformed(path)
        }
    }

    var json: SpecJSON {
        var object: [String: SpecJSON]
        switch self {
        case let .circle(startAngle, sweep):
            object = ["type": .string("circle")]
            object["startAngle"] = startAngle?.json
            object["sweep"] = sweep?.json
        case .rect(let cornerRadius):
            object = ["type": .string("rect")]
            object["cornerRadius"] = cornerRadius?.json
        case let .ring(strokeWidth, startAngle, sweep, segments):
            object = ["type": .string("ring"), "strokeWidth": strokeWidth.json]
            object["startAngle"] = startAngle?.json
            object["sweep"] = sweep?.json
            object["segments"] = segments?.json
        case .triangle:
            object = ["type": .string("triangle")]
        case .line:
            object = ["type": .string("line")]
        }
        return .object(object)
    }
}

extension IndicatorSpec.Stagger {
    init(json: SpecJSON, path: String) throws {
        if let offsets = json.array {
            self = .offsets(try offsets.map { try number($0, path: path) })
        } else if let each = json["each"]?.number {
            self = .each(each, start: json["start"]?.number)
        } else {
            throw malformed(path)
        }
    }

    var json: SpecJSON {
        switch self {
        case .offsets(let offsets):
            return .array(offsets.map(SpecJSON.number))
        case let .each(each, start):
            var object: [String: SpecJSON] = ["each": .number(each)]
            object["start"] = start.map(SpecJSON.number)
            return .object(object)
        }
    }
}

extension IndicatorSpec.KeyframeTrack {
    init(json: SpecJSON, path: String) throws {
        guard
            let property = json["property"]?.string.flatMap(AnimatedProperty.init(rawValue:)),
            let keyTimes = json["keyTimes"]?.array,
            let values = json["values"]?.array
        else { throw malformed(path) }

        self.init(
            property: property,
            keyTimes: try keyTimes.map { try number($0, path: "\(path).keyTimes") },
            values: try values.enumerated().map { index, value in
                try IndicatorSpec.Value(json: value, path: "\(path).values[\(index)]")
            },
            easing: try json["easing"].map { try IndicatorSpec.TrackEasing(json: $0, path: "\(path).easing") }
        )
    }

    var json: SpecJSON {
        var object: [String: SpecJSON] = [
            "property": .string(property.rawValue),
            "keyTimes": .array(keyTimes.map(SpecJSON.number)),
            "values": .array(values.map(\.json)),
        ]
        object["easing"] = easing?.json
        return .object(object)
    }
}

extension IndicatorSpec.TrackEasing {
    init(json: SpecJSON, path: String) throws {
        if SpecValidator.isPerSegment(json), let items = json.array {
            self = .perSegment(try items.map { try IndicatorSpec.Easing(json: $0, path: path) })
        } else {
            self = .uniform(try IndicatorSpec.Easing(json: json, path: path))
        }
    }

    var json: SpecJSON {
        switch self {
        case .uniform(let easing): return easing.json
        case .perSegment(let easings): return .array(easings.map(\.json))
        }
    }
}

extension IndicatorSpec.Easing {
    init(json: SpecJSON, path: String) throws {
        if let name = json.string, let easing = Self(name: name) {
            self = easing
        } else if let points = json.array?.compactMap(\.number), points.count == 4, json.array?.count == 4 {
            self = .cubicBezier(x1: points[0], y1: points[1], x2: points[2], y2: points[3])
        } else {
            throw malformed(path)
        }
    }

    var json: SpecJSON {
        if let name { return .string(name) }
        let points = controlPoints
        return .array([points.x1, points.y1, points.x2, points.y2].map(SpecJSON.number))
    }
}
