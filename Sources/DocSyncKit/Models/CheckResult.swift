import Foundation

/// The aggregated result of checking all rules in a docsync config.
package struct CheckResult: Equatable {
    /// The per-rule statuses produced by the check.
    package let statuses: [RuleStatus]

    /// `true` when every rule is in sync.
    package var allInSync: Bool {
        statuses.allSatisfy(\.isInSync)
    }

    /// Creates a result from the given statuses.
    package init(statuses: [RuleStatus]) {
        self.statuses = statuses
    }

    /// Returns a hook payload when any rule is out of sync, otherwise nil.
    package var claudeHookOutput: ClaudeHookOutput? {
        hookOutput()
    }

    /// Returns a hook payload when any rule is out of sync, otherwise nil.
    package var codexHookOutput: ClaudeHookOutput? {
        hookOutput()
    }

    private func hookOutput() -> ClaudeHookOutput? {
        let lines = statuses.compactMap { status -> String? in
            switch status {
            case let .outOfSync(name, doc, message):
                let body = message ?? "sources changed since last checksum: \(doc)"
                return "out of sync: \(name) — \(body)\nUpdate the doc if needed, then run `docsync update-checksum` to resync the checksum."
            case let .missingChecksum(name):
                return "no checksum stored: \(name) — run `docsync update-checksum` first to initialize the checksum."
            case .inSync:
                return nil
            }
        }
        return lines.isEmpty ? nil : ClaudeHookOutput(reason: lines.joined(separator: "\n"))
    }
}

/// The sync status of a single rule.
package enum RuleStatus: Equatable {
    case inSync(ruleName: String)
    case outOfSync(ruleName: String, doc: String, message: String?)
    case missingChecksum(ruleName: String)

    /// The rule name associated with this status.
    package var ruleName: String {
        switch self {
        case let .inSync(name): name
        case let .outOfSync(name, _, _): name
        case let .missingChecksum(name): name
        }
    }

    /// `true` when this status is `.inSync`.
    package var isInSync: Bool {
        if case .inSync = self { return true }
        return false
    }
}
