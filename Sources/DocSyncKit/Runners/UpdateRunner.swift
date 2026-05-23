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

        let checksums = try await config.rules.asyncMap(numberOfConcurrentTasks: 10) {
            try ChecksumCalculator.calculate(
                sources: $0.sources,
                relativeTo: base,
                fileManager: fileManager,
            )
        }

        for (index, checksum) in checksums.enumerated() {
            config.rules[index].checksum = checksum
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
