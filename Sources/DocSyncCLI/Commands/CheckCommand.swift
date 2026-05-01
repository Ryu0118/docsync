import ArgumentParser
import DocSyncKit
import Foundation

package struct CheckCommand: AsyncParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Verify that docs are in sync with source files."
    )

    @Option(name: [.short, .long], help: "Path to docsync.yml.")
    package var config: String = "docsync.yml"

    package init() {}

    package mutating func run() async throws {
        let configURL = resolvedConfigURL()
        let result = try await CheckRunner(configURL: configURL).run()

        var hasFailure = false
        for status in result.statuses {
            switch status {
            case let .inSync(name):
                print("[docsync] ✅ in sync: \(name)")
            case let .outOfSync(name, doc):
                print("[docsync] ❌ out of sync: \(name)")
                print("  - sources changed but \(doc) not updated")
                hasFailure = true
            case let .missingChecksum(name):
                print("[docsync] ⚠️  no checksum stored: \(name) (run `docsync update` first)")
                hasFailure = true
            }
        }

        if result.statuses.isEmpty {
            print("[docsync] ✅ all docs are in sync")
        } else if !hasFailure {
            print("[docsync] ✅ all docs are in sync")
        }

        if hasFailure {
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
