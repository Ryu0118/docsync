import ArgumentParser
import DocSyncKit
import Foundation

/// Subcommand that recomputes checksums and updates docsync.yml.
package struct UpdateCommand: AsyncParsableCommand {
    /// ArgumentParser command configuration.
    package static let configuration = CommandConfiguration(
        commandName: "update-checksum",
        abstract: "Recompute checksums and update docsync.yml.",
    )

    /// Path to the docsync.yml config file.
    @Option(name: [.short, .long], help: "Path to docsync.yml.")
    package var config: String = "docsync.yml"

    /// Creates a default instance.
    package init() {}

    /// Runs the update-checksum command.
    package mutating func run() async throws {
        try await UpdateRunner(
            configURL: ConfigURL.resolved(from: config),
            mode: .commandLine,
        ).run()
    }
}
