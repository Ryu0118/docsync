import ArgumentParser
import DocSyncKit
import Foundation

package struct UpdateCommand: AsyncParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Recompute checksums and update docsync.yml.",
    )

    @Option(name: [.short, .long], help: "Path to docsync.yml.")
    package var config: String = "docsync.yml"

    package init() {}

    package mutating func run() async throws {
        let configURL = resolvedConfigURL()
        try await UpdateRunner(configURL: configURL).run()
        logger.info("[docsync] ✅ checksums updated", metadata: .plainOutput)
    }

    private func resolvedConfigURL() -> URL {
        let path = config
        if path.hasPrefix("/") {
            return URL(filePath: path)
        }
        return URL(filePath: FileManager.default.currentDirectoryPath)
            .appending(path: path)
    }
}
