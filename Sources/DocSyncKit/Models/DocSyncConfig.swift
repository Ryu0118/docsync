import Foundation

package struct DocSyncConfig: Codable, Equatable, Sendable {
    package var rules: [Rule]

    package init(rules: [Rule]) {
        self.rules = rules
    }
}

extension DocSyncConfig {
    package struct Rule: Codable, Equatable, Sendable {
        package let name: String
        package let sources: [String]
        package let doc: String
        package var checksum: String?

        package init(name: String, sources: [String], doc: String, checksum: String? = nil) {
            self.name = name
            self.sources = sources
            self.doc = doc
            self.checksum = checksum
        }
    }
}
