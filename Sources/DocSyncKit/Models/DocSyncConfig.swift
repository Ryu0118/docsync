import Foundation

/// The top-level structure of a docsync.yml file.
package struct DocSyncConfig: Codable, Equatable {
    /// The list of sync rules defined in the config.
    package var rules: [Rule]

    /// Creates a config with the given rules.
    package init(rules: [Rule]) {
        self.rules = rules
    }
}

package extension DocSyncConfig {
    /// A single rule that ties source files to a documentation file.
    struct Rule: Codable, Equatable {
        /// Unique identifier for this rule.
        package let name: String
        /// Source file paths (relative to the config file) tracked by this rule.
        package let sources: [String]
        /// Documentation file path (relative to the config file) tied to the sources.
        package let doc: String
        /// Optional custom message shown when sources and doc are out of sync.
        package let message: String?
        /// Stored SHA-256 checksum of the source files at last sync.
        package var checksum: String?

        /// Creates a rule with the given fields.
        package init(name: String, sources: [String], doc: String, message: String? = nil, checksum: String? = nil) {
            self.name = name
            self.sources = sources
            self.doc = doc
            self.message = message
            self.checksum = checksum
        }
    }
}
