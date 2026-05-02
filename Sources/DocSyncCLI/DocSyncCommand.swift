import ArgumentParser
import Foundation

/// Root command that groups all docsync subcommands.
package struct DocSyncCommand: AsyncParsableCommand {
    /// ArgumentParser command configuration.
    package static let configuration = CommandConfiguration(
        commandName: "docsync",
        abstract: "Keep documentation in sync with source code.",
        subcommands: [
            CheckCommand.self,
            UpdateCommand.self,
        ],
    )

    /// Creates a default instance.
    package init() {}
}
