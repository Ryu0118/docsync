import Foundation

package struct DocSyncConfig: Codable, Equatable {
    package var rules: [Rule]

    package init(rules: [Rule]) {
        self.rules = rules
    }
}

package extension DocSyncConfig {
    struct Rule: Codable, Equatable {
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
