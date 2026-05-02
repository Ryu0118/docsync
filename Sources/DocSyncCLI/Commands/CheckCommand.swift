import ArgumentParser
import DocSyncKit
import Foundation

/// Subcommand that verifies docs are in sync with source files.
package struct CheckCommand: AsyncParsableCommand {
    /// ArgumentParser command configuration.
    package static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Verify that docs are in sync with source files.",
    )

    /// Path to the docsync.yml config file.
    @Option(name: [.short, .long], help: "Path to docsync.yml.")
    package var config: String = "docsync.yml"

    /// Emit Claude Code PostToolUse hook JSON to stdout.
    @Flag(
        name: .long,
        help: "Emit Claude Code hook JSON to stdout and exit 0. Mutually exclusive with --codex-hook.",
    )
    package var claudeHook: Bool = false

    /// Emit Codex PostToolUse hook JSON to stdout.
    @Flag(
        name: .long,
        help: "Emit Codex hook JSON to stdout and exit 0. Mutually exclusive with --claude-hook.",
    )
    package var codexHook: Bool = false

    /// Creates a default instance.
    package init() {}

    /// Validates that --claude-hook and --codex-hook are not used together.
    package mutating func validate() throws {
        if claudeHook, codexHook {
            throw ValidationError("--claude-hook and --codex-hook are mutually exclusive.")
        }
    }

    /// Runs the check command.
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
