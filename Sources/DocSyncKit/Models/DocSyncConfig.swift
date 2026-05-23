import Foundation

/// The top-level structure of a docsync.yml file.
package struct DocSyncConfig: Codable, Equatable {
    /// The list of sync rules defined in the config.
    package var rules: [Rule]
    /// Glob patterns to remove from the set of candidate files before any rule's
    /// `sources` glob is expanded. Literal (non-glob) source paths bypass excludes
    /// so that explicitly listed files are always honoured.
    package var excludes: [String]

    /// Creates a config with the given rules and optional excludes.
    package init(rules: [Rule], excludes: [String] = []) {
        self.rules = rules
        self.excludes = excludes
    }

    private enum CodingKeys: String, CodingKey {
        case rules
        case excludes
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rules = try container.decode([Rule].self, forKey: .rules)
        excludes = try container.decodeIfPresent([String].self, forKey: .excludes) ?? []
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rules, forKey: .rules)
        if !excludes.isEmpty {
            try container.encode(excludes, forKey: .excludes)
        }
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
