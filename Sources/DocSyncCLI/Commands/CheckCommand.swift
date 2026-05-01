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
        do {
            _ = try await CheckRunner(
                configURL: ConfigURL.resolved(from: config),
                mode: claudeHook ? .claudeHook : .commandLine,
            ).run()
        } catch CheckRunnerError.outOfSync {
            throw ExitCode(1)
        }
    }
}
