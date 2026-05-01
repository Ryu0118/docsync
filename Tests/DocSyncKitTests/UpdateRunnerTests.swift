import Foundation
import Testing

@testable import DocSyncKit

@Suite("UpdateRunner")
struct UpdateRunnerTests {
    private let fm = FileManager.default

    private func makeTempDir() throws -> URL {
        let dir = fm.temporaryDirectory.appending(path: UUID().uuidString)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func write(_ content: String, name: String, in dir: URL) throws {
        try content.write(to: dir.appending(path: name), atomically: true, encoding: .utf8)
    }

    private func writeConfig(_ yaml: String, in dir: URL) throws -> URL {
        let url = dir.appending(path: "docsync.yml")
        try yaml.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test("writes computed checksum to config file")
    func writesChecksum() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        try write("export function user() {}", name: "user.ts", in: dir)
        let yaml = """
        rules:
          - name: api-doc
            sources:
              - user.ts
            doc: docs/api.md
        """
        let configURL = try writeConfig(yaml, in: dir)

        try await UpdateRunner(configURL: configURL).run()

        let loader = ConfigLoader()
        let updated = try loader.load(from: configURL)
        #expect(updated.rules[0].checksum != nil)
        #expect(updated.rules[0].checksum?.isEmpty == false)
    }

    @Test("checksum after update matches direct calculation")
    func checksumMatchesCalculator() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        try write("hello world", name: "src.ts", in: dir)
        let yaml = """
        rules:
          - name: r
            sources: [src.ts]
            doc: d.md
        """
        let configURL = try writeConfig(yaml, in: dir)

        try await UpdateRunner(configURL: configURL).run()

        let expected = try ChecksumCalculator.calculate(sources: ["src.ts"], relativeTo: dir, fileManager: fm)
        let loader = ConfigLoader()
        let config = try loader.load(from: configURL)
        #expect(config.rules[0].checksum == expected)
    }

    @Test("updates existing stale checksum")
    func updatesStaleChecksum() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        try write("new content", name: "a.ts", in: dir)
        let yaml = """
        rules:
          - name: r
            sources: [a.ts]
            doc: d.md
            checksum: stale
        """
        let configURL = try writeConfig(yaml, in: dir)

        try await UpdateRunner(configURL: configURL).run()

        let loader = ConfigLoader()
        let config = try loader.load(from: configURL)
        #expect(config.rules[0].checksum != "stale")
        #expect(config.rules[0].checksum?.count == 64)
    }

    @Test("updates multiple rules independently")
    func updateMultipleRules() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        try write("content a", name: "a.ts", in: dir)
        try write("content b", name: "b.ts", in: dir)
        let yaml = """
        rules:
          - name: r1
            sources: [a.ts]
            doc: d1.md
          - name: r2
            sources: [b.ts]
            doc: d2.md
        """
        let configURL = try writeConfig(yaml, in: dir)

        try await UpdateRunner(configURL: configURL).run()

        let loader = ConfigLoader()
        let config = try loader.load(from: configURL)
        #expect(config.rules[0].checksum?.count == 64)
        #expect(config.rules[1].checksum?.count == 64)
        #expect(config.rules[0].checksum != config.rules[1].checksum)
    }

    @Test("after update, CheckRunner returns allInSync")
    func afterUpdateCheckPasses() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        try write("source content", name: "s.ts", in: dir)
        let yaml = """
        rules:
          - name: r
            sources: [s.ts]
            doc: d.md
        """
        let configURL = try writeConfig(yaml, in: dir)

        try await UpdateRunner(configURL: configURL).run()
        let result = try await CheckRunner(configURL: configURL).run()
        #expect(result.allInSync)
    }

    @Test("throws when config file missing")
    func missingConfig() async throws {
        let url = URL(filePath: "/tmp/nonexistent-\(UUID().uuidString).yml")
        await #expect(throws: (any Error).self) {
            try await UpdateRunner(configURL: url).run()
        }
    }

    @Test("throws when source file missing")
    func missingSourceFile() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        let yaml = """
        rules:
          - name: r
            sources: [missing.ts]
            doc: d.md
        """
        let configURL = try writeConfig(yaml, in: dir)
        await #expect(throws: (any Error).self) {
            try await UpdateRunner(configURL: configURL).run()
        }
    }

    @Test("preserves rule metadata (name, sources, doc) after update")
    func preservesMetadata() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        try write("data", name: "x.ts", in: dir)
        let yaml = """
        rules:
          - name: my-special-rule
            sources: [x.ts]
            doc: special/doc.md
        """
        let configURL = try writeConfig(yaml, in: dir)

        try await UpdateRunner(configURL: configURL).run()

        let loader = ConfigLoader()
        let config = try loader.load(from: configURL)
        #expect(config.rules[0].name == "my-special-rule")
        #expect(config.rules[0].sources == ["x.ts"])
        #expect(config.rules[0].doc == "special/doc.md")
    }
}
