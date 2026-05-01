import ArgumentParser
import DocSyncKit
import Foundation

package struct CheckCommand: AsyncParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Verify that docs are in sync with source files.",
    )

    @Option(name: [.short, .long], help: "Path to docsync.yml.")
    package var config: String = "docsync.yml"

    @Flag(
        name: .long,
        help: "Emit Claude Code PostToolUse hook JSON to stdout and always exit 0.",
    )
    package var claudeHook: Bool = false

    package init() {}

    package mutating func run() async throws {
        let configURL = resolvedConfigURL()
        let result = try await CheckRunner(configURL: configURL).run()

        if claudeHook {
            if let output = result.claudeHookOutput {
                logger.notice("\(output.jsonString)", metadata: .stdoutOutput)
            }
            return
        }

        for status in result.statuses {
            switch status {
            case let .inSync(name):
                logger.info("[docsync] ✅ in sync: \(name)", metadata: .plainOutput)
            case let .outOfSync(name, doc):
                logger.error(
                    "[docsync] ❌ out of sync: \(name)\n  - sources changed but \(doc) not updated",
                    metadata: .plainOutput,
                )
            case let .missingChecksum(name):
                logger.warning(
                    "[docsync] ⚠️  no checksum stored: \(name) (run `docsync update` first)",
                    metadata: .plainOutput,
                )
            }
        }

        if result.statuses.isEmpty || result.allInSync {
            logger.info("[docsync] ✅ all docs are in sync", metadata: .plainOutput)
        }

        if !result.allInSync {
            throw ExitCode(1)
        }
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
