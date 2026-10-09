import Foundation

/// A spec that breaks the schema rules, with every problem found.
public struct IndicatorSpecError: Error, Hashable, Sendable, CustomStringConvertible {
    public let problems: [String]

    public init(problems: [String]) {
        self.problems = problems
    }

    public var description: String {
        "Invalid indicator spec:\n- " + problems.joined(separator: "\n- ")
    }

    static func problems(of error: Error) -> [String] {
        (error as? IndicatorSpecError)?.problems ?? [String(describing: error)]
    }
}

extension IndicatorSpecError: LocalizedError {
    public var errorDescription: String? {
        description
    }
}
