import Foundation

package struct CheckResult: Equatable {
    package let statuses: [RuleStatus]

    package var allInSync: Bool {
        statuses.allSatisfy(\.isInSync)
    }

    package init(statuses: [RuleStatus]) {
        self.statuses = statuses
    }

    /// Returns a Claude Code hook payload when any rule is out of sync, otherwise nil.
    package var claudeHookOutput: ClaudeHookOutput? {
        let lines = statuses.compactMap { status -> String? in
            switch status {
            case let .outOfSync(name, doc):
                return "out of sync: \(name) — sources changed but \(doc) not updated"
            case let .missingChecksum(name):
                return "no checksum stored: \(name) (run `docsync update` first)"
            case .inSync:
                return nil
            }
        }
        return lines.isEmpty ? nil : ClaudeHookOutput(reason: lines.joined(separator: "\n"))
    }
}

package enum RuleStatus: Equatable {
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
