import Foundation

/// The rules of `validate()` in `spec/src/validate.ts`, with the same messages.
enum SpecValidator {
    static let properties = IndicatorSpec.Property.allCases.map(\.rawValue)
    static let groupProperties = IndicatorSpec.GroupProperty.allCases.map(\.rawValue)
    static let strokeProperties: Set<String> = [
        IndicatorSpec.Property.strokeStart.rawValue,
        IndicatorSpec.Property.strokeEnd.rawValue,
    ]
    static let shapes = ["circle", "rect", "ring", "triangle", "line"]
    static let layouts = ["single", "stack", "row", "grid", "ring"]
    static let partFields = ["layout", "shape", "tracks", "stagger", "durations", "rest", "groupTracks"]

    struct Fields {
        var required: [String]
        var optional: [String]
    }

    static let layoutFields: [String: Fields] = [
        "single": Fields(required: [], optional: ["size", "width", "height", "x", "y"]),
        "stack": Fields(required: ["count"], optional: ["size", "width", "height", "x", "y"]),
        "row": Fields(required: ["count", "gap"], optional: ["itemWidth", "itemHeight"]),
        "grid": Fields(required: ["columns", "rows", "gap"], optional: []),
        "ring": Fields(required: ["count", "itemSize"], optional: ["itemWidth", "itemHeight", "startAngle"]),
    ]

    static let shapeFields: [String: Fields] = [
        "circle": Fields(required: [], optional: ["startAngle", "sweep"]),
        "rect": Fields(required: [], optional: ["cornerRadius"]),
        "ring": Fields(required: ["strokeWidth"], optional: ["startAngle", "sweep", "segments"]),
        "triangle": Fields(required: [], optional: []),
        "line": Fields(required: [], optional: []),
    ]

    /// An easing list is per-segment when its first item is not a number.
    static func isPerSegment(_ easing: SpecJSON) -> Bool {
        guard let items = easing.array, let first = items.first else { return false }
        return first.number == nil
    }

    static func validate(_ input: SpecJSON) -> [String] {
        guard let spec = input.object else { return ["spec must be an object"] }
        var errors: [String] = []
        let params = spec["params"]?.object ?? [:]

        func isPositive(_ value: SpecJSON?) -> Bool {
            guard let number = value?.number else { return false }
            return number.isFinite && number > 0
        }

        func isFiniteNumber(_ value: SpecJSON?) -> Bool {
            value?.number?.isFinite ?? false
        }

        func checkNum(_ value: SpecJSON?, _ path: String) {
            if let number = value?.number {
                if !number.isFinite { errors.append("\(path) must be finite") }
            } else if let name = value?["$param"]?.string {
                if params[name] == nil { errors.append("\(path) uses unknown param \"\(name)\"") }
            } else {
                errors.append("\(path) must be a number or { $param }")
            }
        }

        func checkFields(_ object: [String: SpecJSON], _ fields: Fields, _ path: String) {
            for key in fields.required {
                if let value = object[key] {
                    checkNum(value, "\(path).\(key)")
                } else {
                    errors.append("\(path).\(key) is required")
                }
            }
            for key in fields.optional {
                if let value = object[key] { checkNum(value, "\(path).\(key)") }
            }
        }

        func checkTrack(_ track: SpecJSON, path: String, allowed: [String], stroke: Bool, seen: inout Set<String>) {
            guard track.object != nil else {
                errors.append("\(path) must be an object")
                return
            }
            if let property = track["property"]?.string, allowed.contains(property) {
                if seen.contains(property) {
                    errors.append("\(path).property \"\(property)\" is animated by more than one track")
                } else if strokeProperties.contains(property), !stroke {
                    errors.append("\(path).property \"\(property)\" needs a ring shape")
                }
                seen.insert(property)
            } else {
                errors.append("\(path).property must be one of \(allowed.joined(separator: ", "))")
            }

            guard let keyTimes = track["keyTimes"]?.array, keyTimes.count >= 2 else {
                errors.append("\(path).keyTimes needs at least 2 entries")
                return
            }
            for (k, value) in keyTimes.enumerated() {
                if let time = value.number, time.isFinite, time >= 0, time <= 1 {
                    if k > 0, let previous = looseNumber(keyTimes[k - 1]), time < previous {
                        errors.append("\(path).keyTimes must be non-decreasing")
                    }
                } else {
                    errors.append("\(path).keyTimes[\(k)] must be within [0, 1]")
                }
            }
            if let values = track["values"]?.array, values.count == keyTimes.count {
                for (k, value) in values.enumerated() { checkNum(value, "\(path).values[\(k)]") }
            } else {
                errors.append("\(path).values must have the same length as keyTimes")
            }

            if let easing = track["easing"] {
                if isPerSegment(easing), let items = easing.array {
                    if items.count != keyTimes.count - 1 {
                        errors.append("\(path).easing needs one entry per segment (\(keyTimes.count - 1))")
                    }
                    for (k, item) in items.enumerated() { checkEasing(item, "\(path).easing[\(k)]", &errors) }
                } else {
                    checkEasing(easing, "\(path).easing", &errors)
                }
            }
        }

        func checkTracks(_ tracks: SpecJSON?, path: String, allowed: [String], stroke: Bool) -> Int {
            guard let tracks else { return 0 }
            guard let items = tracks.array else {
                errors.append("\(path) must be an array")
                return 0
            }
            var seen = Set<String>()
            for (index, track) in items.enumerated() {
                checkTrack(track, path: "\(path)[\(index)]", allowed: allowed, stroke: stroke, seen: &seen)
            }
            return items.count
        }

        /// Checks one group of elements; returns its number of tracks and group tracks.
        func checkPart(_ part: [String: SpecJSON], prefix: String) -> Int {
            func at(_ field: String) -> String { prefix + field }

            if let layout = part["layout"]?.object,
               let type = layout["type"]?.string,
               let fields = layoutFields[type] {
                checkFields(layout, fields, at("layout"))
                if let orient = layout["orient"], orient.bool == nil {
                    errors.append("\(at("layout.orient")) must be a boolean")
                }
            } else {
                errors.append("\(at("layout.type")) must be one of \(layouts.joined(separator: ", "))")
            }

            var stroke = false
            if let shape = part["shape"]?.object,
               let type = shape["type"]?.string,
               let fields = shapeFields[type] {
                stroke = type == "ring"
                checkFields(shape, fields, at("shape"))
                if let sweep = shape["sweep"]?.number, sweep.isFinite, !(sweep > 0 && sweep <= 2 * .pi + 1e-9) {
                    errors.append("\(at("shape.sweep")) must be within (0, 2π]")
                }
            } else {
                errors.append("\(at("shape.type")) must be one of \(shapes.joined(separator: ", "))")
            }

            if let stagger = part["stagger"] {
                if let offsets = stagger.array {
                    for (index, value) in offsets.enumerated() where !isFiniteNumber(value) {
                        errors.append("\(at("stagger[\(index)]")) must be a finite number")
                    }
                } else if stagger.object == nil || !isFiniteNumber(stagger["each"]) {
                    errors.append("\(at("stagger")) must be an array of offsets or { each, start? }")
                } else if let start = stagger["start"], !isFiniteNumber(start) {
                    errors.append("\(at("stagger.start")) must be a finite number")
                }
            }

            if let duration = part["duration"], !prefix.isEmpty, !isPositive(duration) {
                errors.append("\(at("duration")) must be a positive number")
            }
            if let durations = part["durations"] {
                if let items = durations.array {
                    for (index, value) in items.enumerated() where !isPositive(value) {
                        errors.append("\(at("durations[\(index)]")) must be a positive number")
                    }
                } else {
                    errors.append("\(at("durations")) must be an array")
                }
            }

            if let rest = part["rest"] {
                if let object = rest.object {
                    for (property, value) in object.sorted(by: { $0.key < $1.key }) {
                        if !properties.contains(property) {
                            errors.append("\(at("rest.\(property)")) is not an animatable property")
                        } else if strokeProperties.contains(property), !stroke {
                            errors.append("\(at("rest.\(property)")) needs a ring shape")
                        } else {
                            checkNum(value, at("rest.\(property)"))
                        }
                    }
                } else {
                    errors.append("\(at("rest")) must be an object")
                }
            }

            return checkTracks(part["tracks"], path: at("tracks"), allowed: properties, stroke: stroke)
                + checkTracks(part["groupTracks"], path: at("groupTracks"), allowed: groupProperties, stroke: stroke)
        }

        if spec["schemaVersion"]?.number != Double(IndicatorSpec.currentSchemaVersion) {
            errors.append("schemaVersion must be \(IndicatorSpec.currentSchemaVersion)")
        }
        if spec["name"]?.string?.isEmpty ?? true {
            errors.append("name is required")
        }
        if !isPositive(spec["duration"]) {
            errors.append("duration must be a positive number")
        }
        if let rawParams = spec["params"] {
            if let object = rawParams.object {
                for (name, value) in object.sorted(by: { $0.key < $1.key }) where !isFiniteNumber(value) {
                    errors.append("params.\(name) must be a finite number")
                }
            } else {
                errors.append("params must be an object")
            }
        }
        if let perspective = spec["perspective"], !isPositive(perspective) {
            errors.append("perspective must be a positive number")
        }

        var animated = 0
        if let parts = spec["parts"] {
            for field in partFields where spec[field] != nil {
                errors.append("\(field) must be set inside parts when the spec has parts")
            }
            if let items = parts.array, !items.isEmpty {
                for (index, part) in items.enumerated() {
                    if let object = part.object {
                        animated += checkPart(object, prefix: "parts[\(index)].")
                    } else {
                        errors.append("parts[\(index)] must be an object")
                    }
                }
            } else {
                errors.append("parts must be a non-empty array")
            }
        } else {
            animated = checkPart(spec, prefix: "")
        }
        if animated == 0 && errors.isEmpty {
            errors.append("the spec needs at least one track or group track")
        }

        return errors
    }

    /// The number JavaScript's `<` compares a JSON value as, or `nil` for NaN.
    private static func looseNumber(_ value: SpecJSON) -> Double? {
        switch value {
        case .number(let number): return number
        case .null: return 0
        case .bool(let bool): return bool ? 1 : 0
        case .string(let string):
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? 0 : Double(trimmed)
        case .array, .object: return nil
        }
    }

    private static func checkEasing(_ easing: SpecJSON, _ path: String, _ errors: inout [String]) {
        if let name = easing.string {
            if IndicatorSpec.Easing(name: name) == nil { errors.append("\(path) \"\(name)\" is not a named easing") }
            return
        }
        guard let items = easing.array, items.count == 4 else {
            errors.append("\(path) must be a named easing or [x1, y1, x2, y2]")
            return
        }
        let points = items.compactMap(\.number).filter(\.isFinite)
        guard points.count == 4 else {
            errors.append("\(path) must be a named easing or [x1, y1, x2, y2]")
            return
        }
        if points[0] < 0 || points[0] > 1 || points[2] < 0 || points[2] > 1 {
            errors.append("\(path) x1 and x2 must be within [0, 1]")
        }
    }
}
