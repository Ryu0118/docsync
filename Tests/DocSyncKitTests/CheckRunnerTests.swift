import Foundation
import Testing

@testable import DocSyncKit

@Suite("CheckRunner")
struct CheckRunnerTests {
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

    // MARK: - Setup helpers

    private func makeInSyncSetup() throws -> URL {
        let dir = try makeTempDir()
        try write("console.log('user');", name: "user.ts", in: dir)

        let checksum = try ChecksumCalculator.calculate(sources: ["user.ts"], relativeTo: dir, fileManager: fm)
        let yaml = """
        rules:
          - name: api-doc
            sources:
              - user.ts
            doc: docs/api.md
            checksum: \(checksum)
        """
        return try writeConfig(yaml, in: dir)
    }

    // MARK: - Tests

    @Test("returns inSync when checksum matches")
    func inSync() async throws {
        let configURL = try makeInSyncSetup()
        defer { try? fm.removeItem(at: configURL.deletingLastPathComponent()) }

        let result = try await CheckRunner(configURL: configURL).run()
        #expect(result.allInSync)
        #expect(result.statuses.count == 1)
        if case let .inSync(name) = result.statuses[0] {
            #expect(name == "api-doc")
        } else {
            Issue.record("Expected inSync status")
        }
    }

    @Test("returns outOfSync when source file changes")
    func outOfSync() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        try write("original content", name: "user.ts", in: dir)
        let yaml = """
        rules:
          - name: api-doc
            sources:
              - user.ts
            doc: docs/api.md
            checksum: stale-checksum
        """
        let configURL = try writeConfig(yaml, in: dir)

        let result = try await CheckRunner(configURL: configURL).run()
        #expect(!result.allInSync)
        if case let .outOfSync(name, doc) = result.statuses[0] {
            #expect(name == "api-doc")
            #expect(doc == "docs/api.md")
        } else {
            Issue.record("Expected outOfSync status")
        }
    }

    @Test("returns missingChecksum when no checksum stored")
    func missingChecksum() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        try write("content", name: "a.ts", in: dir)
        let yaml = """
        rules:
          - name: my-rule
            sources:
              - a.ts
            doc: docs/a.md
        """
        let configURL = try writeConfig(yaml, in: dir)

        let result = try await CheckRunner(configURL: configURL).run()
        #expect(!result.allInSync)
        if case let .missingChecksum(name) = result.statuses[0] {
            #expect(name == "my-rule")
        } else {
            Issue.record("Expected missingChecksum status")
        }
    }

    @Test("returns missingChecksum for empty string checksum")
    func emptyChecksum() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        try write("content", name: "a.ts", in: dir)
        let yaml = """
        rules:
          - name: my-rule
            sources:
              - a.ts
            doc: docs/a.md
            checksum: ""
        """
        let configURL = try writeConfig(yaml, in: dir)

        let result = try await CheckRunner(configURL: configURL).run()
        #expect(!result.allInSync)
        if case .missingChecksum = result.statuses[0] {
            // expected
        } else {
            Issue.record("Expected missingChecksum for empty checksum")
        }
    }

    @Test("handles multiple rules with mixed statuses")
    func multipleRulesMixed() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        try write("file a", name: "a.ts", in: dir)
        try write("file b", name: "b.ts", in: dir)

        let goodChecksum = try ChecksumCalculator.calculate(sources: ["a.ts"], relativeTo: dir, fileManager: fm)
        let yaml = """
        rules:
          - name: good-rule
            sources:
              - a.ts
            doc: docs/a.md
            checksum: \(goodChecksum)
          - name: bad-rule
            sources:
              - b.ts
            doc: docs/b.md
            checksum: wrong-checksum
        """
        let configURL = try writeConfig(yaml, in: dir)

        let result = try await CheckRunner(configURL: configURL).run()
        #expect(!result.allInSync)
        #expect(result.statuses.count == 2)

        if case let .inSync(name) = result.statuses[0] {
            #expect(name == "good-rule")
        } else {
            Issue.record("Expected first rule inSync")
        }
        if case let .outOfSync(name, _) = result.statuses[1] {
            #expect(name == "bad-rule")
        } else {
            Issue.record("Expected second rule outOfSync")
        }
    }

    @Test("all rules in sync produces allInSync=true")
    func allInSync() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        try write("alpha", name: "a.ts", in: dir)
        try write("beta", name: "b.ts", in: dir)

        let cs1 = try ChecksumCalculator.calculate(sources: ["a.ts"], relativeTo: dir, fileManager: fm)
        let cs2 = try ChecksumCalculator.calculate(sources: ["b.ts"], relativeTo: dir, fileManager: fm)
        let yaml = """
        rules:
          - name: r1
            sources: [a.ts]
            doc: d1.md
            checksum: \(cs1)
          - name: r2
            sources: [b.ts]
            doc: d2.md
            checksum: \(cs2)
        """
        let configURL = try writeConfig(yaml, in: dir)

        let result = try await CheckRunner(configURL: configURL).run()
        #expect(result.allInSync)
    }

    @Test("empty rules list returns allInSync=true")
    func emptyRules() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        let yaml = "rules: []\n"
        let configURL = try writeConfig(yaml, in: dir)

        let result = try await CheckRunner(configURL: configURL).run()
        #expect(result.allInSync)
        #expect(result.statuses.isEmpty)
    }

    @Test("throws when config file missing")
    func missingConfig() async throws {
        let url = URL(filePath: "/tmp/nonexistent-\(UUID().uuidString).yml")
        await #expect(throws: (any Error).self) {
            try await CheckRunner(configURL: url).run()
        }
    }

    @Test("throws when source file missing")
    func missingSourceFile() async throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        let yaml = """
        rules:
          - name: r
            sources:
              - nonexistent.ts
            doc: d.md
            checksum: abc
        """
        let configURL = try writeConfig(yaml, in: dir)
        await #expect(throws: (any Error).self) {
            try await CheckRunner(configURL: configURL).run()
        }
    }
}
