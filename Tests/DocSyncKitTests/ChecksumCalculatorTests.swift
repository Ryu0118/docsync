@testable import DocSyncKit
import Foundation
import Testing

@Suite
struct ChecksumCalculatorTests {
    private let fm = FileManager.default

    private func makeTempDir() throws -> URL {
        let dir = fm.temporaryDirectory.appending(path: UUID().uuidString)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func write(_ content: String, name: String, in dir: URL) throws {
        let url = dir.appending(path: name)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    @Test
    func `single file produces non empty hex string`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("hello", name: "a.ts", in: dir)

        let checksum = try ChecksumCalculator.calculate(
            sources: ["a.ts"],
            relativeTo: dir,
            fileManager: fm,
        )
        #expect(!checksum.isEmpty)
        #expect(checksum.count == 64)
    }

    @Test
    func `same content always produces same checksum`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("consistent", name: "a.ts", in: dir)

        let first = try ChecksumCalculator.calculate(sources: ["a.ts"], relativeTo: dir, fileManager: fm)
        let second = try ChecksumCalculator.calculate(sources: ["a.ts"], relativeTo: dir, fileManager: fm)
        #expect(first == second)
    }

    @Test
    func `changing file content changes checksum`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("version1", name: "a.ts", in: dir)
        let before = try ChecksumCalculator.calculate(sources: ["a.ts"], relativeTo: dir, fileManager: fm)

        try write("version2", name: "a.ts", in: dir)
        let after = try ChecksumCalculator.calculate(sources: ["a.ts"], relativeTo: dir, fileManager: fm)

        #expect(before != after)
    }

    @Test
    func `sources are sorted before hashing`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("aaa", name: "a.ts", in: dir)
        try write("bbb", name: "b.ts", in: dir)

        let checksumAB = try ChecksumCalculator.calculate(sources: ["a.ts", "b.ts"], relativeTo: dir, fileManager: fm)
        let checksumBA = try ChecksumCalculator.calculate(sources: ["b.ts", "a.ts"], relativeTo: dir, fileManager: fm)
        #expect(checksumAB == checksumBA)
    }

    @Test
    func `empty file produces valid checksum`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("", name: "empty.ts", in: dir)

        let checksum = try ChecksumCalculator.calculate(sources: ["empty.ts"], relativeTo: dir, fileManager: fm)
        #expect(checksum.count == 64)
    }

    @Test
    func `missing source file throws checksum error`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        #expect(throws: ChecksumError.self) {
            try ChecksumCalculator.calculate(sources: ["nonexistent.ts"], relativeTo: dir, fileManager: fm)
        }
    }

    @Test
    func `different content produces different checksums`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("rule1 content", name: "r1.ts", in: dir)
        try write("rule2 content", name: "r2.ts", in: dir)

        let checksumR1 = try ChecksumCalculator.calculate(sources: ["r1.ts"], relativeTo: dir, fileManager: fm)
        let checksumR2 = try ChecksumCalculator.calculate(sources: ["r2.ts"], relativeTo: dir, fileManager: fm)
        #expect(checksumR1 != checksumR2)
    }

    @Test
    func `binary data produces valid checksum`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        let bytes: [UInt8] = [0x00, 0xFF, 0x0A, 0x1B, 0x7F]
        let url = dir.appending(path: "binary.bin")
        try Data(bytes).write(to: url)

        let checksum = try ChecksumCalculator.calculate(sources: ["binary.bin"], relativeTo: dir, fileManager: fm)
        #expect(checksum.count == 64)
    }

    @Test
    func `checksum is lowercase hex string`() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("test", name: "t.ts", in: dir)

        let checksum = try ChecksumCalculator.calculate(sources: ["t.ts"], relativeTo: dir, fileManager: fm)
        let allowed = CharacterSet(charactersIn: "0123456789abcdef")
        #expect(checksum.unicodeScalars.allSatisfy { allowed.contains($0) })
    }
}
