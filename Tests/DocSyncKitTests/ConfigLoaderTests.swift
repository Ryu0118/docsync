@testable import DocSyncKit
import Foundation
import Testing

@Suite
struct ConfigLoaderTests {
    private let fm = FileManager.default
    private let loader = ConfigLoader()

    private func makeTempDir() throws -> URL {
        let dir = fm.temporaryDirectory.appending(path: UUID().uuidString)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func write(_ content: String, name: String, in dir: URL) throws -> URL {
        let url = dir.appending(path: name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - load

    @Test
    func `loads valid YAML with checksum`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        let yaml = """
        rules:
          - name: api-doc
            sources:
              - src/api/user.ts
            doc: docs/api.md
            checksum: abc123
        """
        let url = try write(yaml, name: "docsync.yml", in: dir)

        let config = try loader.load(from: url)
        #expect(config.rules.count == 1)
        #expect(config.rules[0].name == "api-doc")
        #expect(config.rules[0].sources == ["src/api/user.ts"])
        #expect(config.rules[0].doc == "docs/api.md")
        #expect(config.rules[0].checksum == "abc123")
    }

    @Test
    func `loads YAML without checksum field`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        let yaml = """
        rules:
          - name: readme
            sources:
              - src/main.ts
            doc: README.md
        """
        let url = try write(yaml, name: "docsync.yml", in: dir)
        let config = try loader.load(from: url)
        #expect(config.rules[0].checksum == nil)
    }

    @Test
    func `loads YAML with multiple rules`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        let yaml = """
        rules:
          - name: r1
            sources: [a.ts]
            doc: d1.md
          - name: r2
            sources: [b.ts, c.ts]
            doc: d2.md
            checksum: beef
        """
        let url = try write(yaml, name: "docsync.yml", in: dir)
        let config = try loader.load(from: url)
        #expect(config.rules.count == 2)
        #expect(config.rules[1].sources == ["b.ts", "c.ts"])
    }

    @Test
    func `throws fileNotFound for missing file`() throws {
        let url = URL(filePath: "/tmp/nonexistent-docsync-\(UUID().uuidString).yml")
        #expect(throws: ConfigError.self) {
            try loader.load(from: url)
        }
    }

    @Test
    func `throws on malformed YAML`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        let url = try write("rules: [[[invalid", name: "docsync.yml", in: dir)
        #expect(throws: (any Error).self) {
            try loader.load(from: url)
        }
    }

    // MARK: - save

    @Test
    func `save round-trips correctly`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        let url = dir.appending(path: "docsync.yml")

        let config = DocSyncConfig(rules: [
            DocSyncConfig.Rule(name: "r", sources: ["x.ts"], doc: "d.md", checksum: "1234"),
        ])
        try loader.save(config, to: url)

        let loaded = try loader.load(from: url)
        #expect(loaded == config)
    }

    @Test
    func `save updates existing file with new checksum`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        let yaml = """
        rules:
          - name: r
            sources: [x.ts]
            doc: d.md
            checksum: old
        """
        let url = try write(yaml, name: "docsync.yml", in: dir)

        var config = try loader.load(from: url)
        config.rules[0].checksum = "newchecksum"
        try loader.save(config, to: url)

        let reloaded = try loader.load(from: url)
        #expect(reloaded.rules[0].checksum == "newchecksum")
    }
}
