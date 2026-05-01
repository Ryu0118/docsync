import Foundation
import Testing
import Yams

@testable import DocSyncKit

@Suite("DocSyncConfig")
struct DocSyncConfigTests {
    @Test("round-trip encoding/decoding preserves all fields")
    func roundTrip() throws {
        let original = DocSyncConfig(rules: [
            DocSyncConfig.Rule(
                name: "api-doc",
                sources: ["src/api/user.ts", "src/api/order.ts"],
                doc: "docs/api.md",
                checksum: "abc123"
            ),
            DocSyncConfig.Rule(
                name: "readme",
                sources: ["src/main.ts"],
                doc: "README.md",
                checksum: nil
            ),
        ])

        let yaml = try YAMLEncoder().encode(original)
        let decoded = try YAMLDecoder().decode(DocSyncConfig.self, from: yaml)
        #expect(decoded == original)
    }

    @Test("Rule with no checksum decodes as nil")
    func ruleNoChecksum() throws {
        let yaml = """
        rules:
          - name: api-doc
            sources:
              - src/api/user.ts
            doc: docs/api.md
        """
        let config = try YAMLDecoder().decode(DocSyncConfig.self, from: yaml)
        #expect(config.rules.count == 1)
        #expect(config.rules[0].checksum == nil)
    }

    @Test("Rule with checksum decodes correctly")
    func ruleWithChecksum() throws {
        let yaml = """
        rules:
          - name: my-rule
            sources:
              - a.swift
            doc: docs/a.md
            checksum: deadbeef
        """
        let config = try YAMLDecoder().decode(DocSyncConfig.self, from: yaml)
        #expect(config.rules[0].checksum == "deadbeef")
    }

    @Test("empty rules list decodes")
    func emptyRules() throws {
        let yaml = "rules: []\n"
        let config = try YAMLDecoder().decode(DocSyncConfig.self, from: yaml)
        #expect(config.rules.isEmpty)
    }

    @Test("multiple sources preserved in order")
    func multipleSourcesOrder() throws {
        let sources = ["c.ts", "a.ts", "b.ts"]
        let rule = DocSyncConfig.Rule(name: "r", sources: sources, doc: "d.md", checksum: nil)
        let config = DocSyncConfig(rules: [rule])
        let yaml = try YAMLEncoder().encode(config)
        let decoded = try YAMLDecoder().decode(DocSyncConfig.self, from: yaml)
        #expect(decoded.rules[0].sources == sources)
    }
}
