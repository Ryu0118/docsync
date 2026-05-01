import Foundation

package struct CheckResult: Equatable, Sendable {
    package let statuses: [RuleStatus]

    package var allInSync: Bool {
        statuses.allSatisfy { $0.isInSync }
    }

    package init(statuses: [RuleStatus]) {
        self.statuses = statuses
    }
}

package enum RuleStatus: Equatable, Sendable {
    case inSync(ruleName: String)
    case outOfSync(ruleName: String, doc: String)
    case missingChecksum(ruleName: String)

    package var ruleName: String {
        switch self {
        case let .inSync(name): name
        case let .outOfSync(name, _): name
        case let .missingChecksum(name): name
        }
    }

    package var isInSync: Bool {
        if case .inSync = self { return true }
        return false
    }
}
