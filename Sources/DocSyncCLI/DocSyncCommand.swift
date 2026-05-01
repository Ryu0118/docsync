import ArgumentParser
import Foundation

package struct DocSyncCommand: AsyncParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "docsync",
        abstract: "Keep documentation in sync with source code.",
        subcommands: [
            CheckCommand.self,
            UpdateCommand.self,
        ],
    )

    package init() {}
}
