import AsyncOperations
import FileManagerProtocol
import Foundation

/// Recomputes checksums for all rules and writes them back to docsync.yml.
package struct UpdateRunner {
    private let mode: UpdateRunnerMode
    private let configURL: URL
    private let fileManager: any FileManagerProtocol
    private let configLoader: ConfigLoader

    /// Creates a runner for the given config file.
    package init(
        configURL: URL,
        mode: UpdateRunnerMode = .updateOnly,
        fileManager: some FileManagerProtocol = FileManager.default,
    ) {
        self.mode = mode
        self.configURL = configURL
        self.fileManager = fileManager
        configLoader = ConfigLoader(fileManager: fileManager)
    }

    /// Recomputes all checksums and saves the updated config.
    package func run() async throws {
        var config = try configLoader.load(from: configURL)
        let base = configURL.deletingLastPathComponent()

        let allFiles = try GlobExpander.collectAllFiles(under: base, fileManager: fileManager)
        let checksums = try await config.rules.asyncMap(numberOfConcurrentTasks: 10) { rule in
            try ChecksumCalculator.calculate(
                sources: rule.sources,
                relativeTo: base,
                fileManager: fileManager,
                cachedAllFiles: allFiles,
            )
        }

        config.rules = zip(config.rules, checksums).map { rule, checksum in
            var updated = rule
            updated.checksum = checksum
            return updated
        }

        try configLoader.save(config, to: configURL)
        if mode == .commandLine {
            logger.info("[docsync] ✅ checksums updated", metadata: .plainOutput)
        }
    }
}

/// Execution mode for ``UpdateRunner``.
package enum UpdateRunnerMode: Equatable {
    case updateOnly
    case commandLine
}
