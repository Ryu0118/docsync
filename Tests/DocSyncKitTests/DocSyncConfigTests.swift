// swiftformat:disable redundantSwiftTestingSuite
@testable import DocSyncKit
import Foundation
import Testing
import Yams

@Suite
struct DocSyncConfigTests {
    @Test
    func `round trip encoding decoding preserves all fields`() throws {
        let original = DocSyncConfig(rules: [
            DocSyncConfig.Rule(
                name: "api-doc",
                sources: ["src/api/user.ts", "src/api/order.ts"],
                doc: "docs/api.md",
                checksum: "abc123",
            ),
            DocSyncConfig.Rule(
                name: "readme",
                sources: ["src/main.ts"],
                doc: "README.md",
                checksum: nil,
            ),
        ])

        let yaml = try YAMLEncoder().encode(original)
        let decoded = try YAMLDecoder().decode(DocSyncConfig.self, from: yaml)
        #expect(decoded == original)
    }

    @Test
    func `rule with no checksum decodes as nil`() throws {
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

    @Test
    func `rule with checksum decodes correctly`() throws {
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

    @Test
    func `empty rules list decodes`() throws {
        let yaml = "rules: []\n"
        let config = try YAMLDecoder().decode(DocSyncConfig.self, from: yaml)
        #expect(config.rules.isEmpty)
    }

    @Test
    func `multiple sources preserved in order`() throws {
        let sources = ["c.ts", "a.ts", "b.ts"]
        let rule = DocSyncConfig.Rule(name: "rrr", sources: sources, doc: "d.md", checksum: nil)
        let config = DocSyncConfig(rules: [rule])
        let yaml = try YAMLEncoder().encode(config)
        let decoded = try YAMLDecoder().decode(DocSyncConfig.self, from: yaml)
        #expect(decoded.rules[0].sources == sources)
    }
}
