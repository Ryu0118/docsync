import FileManagerProtocol
import Foundation

package struct CheckRunner: Sendable {
    private let configURL: URL
    private let fileManager: any FileManagerProtocol
    private let configLoader: ConfigLoader

    package init(
        configURL: URL,
        fileManager: some FileManagerProtocol = FileManager.default
    ) {
        self.configURL = configURL
        self.fileManager = fileManager
        self.configLoader = ConfigLoader(fileManager: fileManager)
    }

    package func run() async throws -> CheckResult {
        let config = try configLoader.load(from: configURL)
        let base = configURL.deletingLastPathComponent()

        var statuses: [RuleStatus] = []
        for rule in config.rules {
            let status = try evaluate(rule: rule, base: base)
            statuses.append(status)
        }
        return CheckResult(statuses: statuses)
    }

    private func evaluate(rule: DocSyncConfig.Rule, base: URL) throws -> RuleStatus {
        guard let stored = rule.checksum, !stored.isEmpty else {
            return .missingChecksum(ruleName: rule.name)
        }
        let computed = try ChecksumCalculator.calculate(
            sources: rule.sources,
            relativeTo: base,
            fileManager: fileManager
        )
        if computed == stored {
            return .inSync(ruleName: rule.name)
        } else {
            return .outOfSync(ruleName: rule.name, doc: rule.doc)
        }
    }
}
