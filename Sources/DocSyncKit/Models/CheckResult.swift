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
            case let .outOfSync(name, doc, message):
                let body = message ?? "sources changed but \(doc) not updated"
                return "out of sync: \(name) — \(body)\nAfter updating the docs, run `docsync update` to refresh the checksum."
            case let .missingChecksum(name):
                return "no checksum stored: \(name) — run `docsync update` first to initialize the checksum."
            case .inSync:
                return nil
            }
        }
        return lines.isEmpty ? nil : ClaudeHookOutput(reason: lines.joined(separator: "\n"))
    }
}

package enum RuleStatus: Equatable {
    case inSync(ruleName: String)
    case outOfSync(ruleName: String, doc: String, message: String?)
    case missingChecksum(ruleName: String)

    package var ruleName: String {
        switch self {
        case let .inSync(name): name
        case let .outOfSync(name, _, _): name
        case let .missingChecksum(name): name
        }
    }

    package var isInSync: Bool {
        if case .inSync = self { return true }
        return false
    }
}
