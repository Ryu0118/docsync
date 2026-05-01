import FileManagerProtocol
import Foundation

package struct UpdateRunner {
    private let mode: UpdateRunnerMode
    private let configURL: URL
    private let fileManager: any FileManagerProtocol
    private let configLoader: ConfigLoader

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

    package func run() async throws {
        var config = try configLoader.load(from: configURL)
        let base = configURL.deletingLastPathComponent()

        for index in config.rules.indices {
            let checksum = try ChecksumCalculator.calculate(
                sources: config.rules[index].sources,
                relativeTo: base,
                fileManager: fileManager,
            )
            config.rules[index].checksum = checksum
        }

        try configLoader.save(config, to: configURL)
        if mode == .commandLine {
            logger.info("[docsync] ✅ checksums updated", metadata: .plainOutput)
        }
    }
}

package enum UpdateRunnerMode: Equatable {
    case updateOnly
    case commandLine
}
