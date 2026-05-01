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
        if claudeHook {
            do {
                let result = try await CheckRunner(configURL: ConfigURL.resolved(from: config)).run()
                if let output = result.claudeHookOutput {
                    logger.notice("\(output.jsonString)", metadata: .stdoutOutput)
                }
            } catch {
                // Swallow errors in hook mode to guarantee exit 0.
            }
            return
        }

        let configURL = ConfigURL.resolved(from: config)
        let result = try await CheckRunner(configURL: configURL).run()

        for status in result.statuses {
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

        if result.statuses.isEmpty || result.allInSync {
            logger.info("[docsync] ✅ all docs are in sync", metadata: .plainOutput)
        }

        if !result.allInSync {
            throw ExitCode(1)
        }
    }
}
