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
        help: "Emit Claude Code hook JSON to stdout and exit 0. Mutually exclusive with --codex-hook.",
    )
    package var claudeHook: Bool = false

    @Flag(
        name: .long,
        help: "Emit Codex hook JSON to stdout and exit 0. Mutually exclusive with --claude-hook.",
    )
    package var codexHook: Bool = false

    package init() {}

    package mutating func validate() throws {
        if claudeHook, codexHook {
            throw ValidationError("--claude-hook and --codex-hook are mutually exclusive.")
        }
    }

    package mutating func run() async throws {
        let mode: CheckRunnerMode = claudeHook ? .claudeHook : codexHook ? .codexHook : .commandLine
        do {
            _ = try await CheckRunner(
                configURL: ConfigURL.resolved(from: config),
                mode: mode,
            ).run()
        } catch CheckRunnerError.outOfSync {
            throw ExitCode(1)
        }
    }
}
