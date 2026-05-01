import FileManagerProtocol
import Foundation

package struct CheckRunner {
    private let mode: CheckRunnerMode
    private let configURL: URL
    private let fileManager: any FileManagerProtocol
    private let configLoader: ConfigLoader

    package init(
        configURL: URL,
        mode: CheckRunnerMode = .evaluateOnly,
        fileManager: some FileManagerProtocol = FileManager.default,
    ) {
        self.mode = mode
        self.configURL = configURL
        self.fileManager = fileManager
        configLoader = ConfigLoader(fileManager: fileManager)
    }

    package func run() async throws -> CheckResult {
        switch mode {
        case .claudeHook:
            return await runHook(output: \.claudeHookOutput)
        case .codexHook:
            return await runHook(output: \.codexHookOutput)
        case .evaluateOnly, .commandLine:
            let result = try evaluateConfig()
            if mode == .commandLine {
                log(result)
                if !result.allInSync {
                    throw CheckRunnerError.outOfSync
                }
            }
            return result
        }
    }

    private func runHook(output keyPath: KeyPath<CheckResult, ClaudeHookOutput?>) async -> CheckResult {
        do {
            let result = try evaluateConfig()
            if let output = result[keyPath: keyPath] {
                logger.notice("\(output.jsonString)", metadata: .stdoutOutput)
            }
            return result
        } catch {
            return CheckResult(statuses: [])
        }
    }

    private func evaluateConfig() throws -> CheckResult {
        let config = try configLoader.load(from: configURL)
        let base = configURL.deletingLastPathComponent()

        var statuses: [RuleStatus] = []
        for rule in config.rules {
            let status = try evaluate(rule: rule, base: base)
            statuses.append(status)
        }
        return CheckResult(statuses: statuses)
    }

    private func log(_ result: CheckResult) {
        for status in result.statuses {
            log(status)
        }

        if result.statuses.isEmpty || result.allInSync {
            logger.info("[docsync] ✅ all docs are in sync", metadata: .plainOutput)
        }
    }

    private func log(_ status: RuleStatus) {
        switch status {
        case let .inSync(name):
            logger.info("[docsync] ✅ in sync: \(name)", metadata: .plainOutput)
        case let .outOfSync(name, doc, message):
            let body = message ?? "sources changed but \(doc) not updated"
            logger.error(
                "[docsync] ❌ out of sync: \(name)\n  - \(body)\n  After updating the docs, run `docsync update` to refresh the checksum.",
                metadata: .plainOutput,
            )
        case let .missingChecksum(name):
            logger.warning(
                "[docsync] ⚠️  no checksum stored: \(name) (run `docsync update` first)",
                metadata: .plainOutput,
            )
        }
    }

    private func evaluate(rule: DocSyncConfig.Rule, base: URL) throws -> RuleStatus {
        guard let stored = rule.checksum, !stored.isEmpty else {
            return .missingChecksum(ruleName: rule.name)
        }
        let computed = try ChecksumCalculator.calculate(
            sources: rule.sources,
            relativeTo: base,
            fileManager: fileManager,
        )
        return if computed == stored {
            .inSync(ruleName: rule.name)
        } else {
            .outOfSync(ruleName: rule.name, doc: rule.doc, message: rule.message)
        }
    }
}

package enum CheckRunnerMode: Equatable {
    case evaluateOnly
    case commandLine
    case claudeHook
    case codexHook
}

package enum CheckRunnerError: Error, Equatable {
    case outOfSync
}
