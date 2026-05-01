import ArgumentParser
import DocSyncKit
import Foundation

package struct UpdateCommand: AsyncParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "update-checksum",
        abstract: "Recompute checksums and update docsync.yml.",
    )

    @Option(name: [.short, .long], help: "Path to docsync.yml.")
    package var config: String = "docsync.yml"

    package init() {}

    package mutating func run() async throws {
        try await UpdateRunner(
            configURL: ConfigURL.resolved(from: config),
            mode: .commandLine,
        ).run()
    }
}
