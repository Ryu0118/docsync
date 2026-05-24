// swiftformat:disable redundantSwiftTestingSuite
@testable import DocSyncKit
import Foundation
import Testing

@Suite
struct CollectAllFilesTests {
    private let fm = FileManager.default

    private func makeTempDir() throws -> URL {
        let dir = fm.temporaryDirectory.appending(path: UUID().uuidString)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func write(_ content: String, at relativePath: String, in dir: URL) throws {
        let url = dir.appending(path: relativePath)
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    @Test
    func emptyExcludesMatchesPlainOverload() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("x", at: "Sources/A.swift", in: dir)
        try write("x", at: ".build/cached.swift", in: dir)

        let plain = try GlobExpander.collectAllFiles(under: dir, fileManager: fm)
        let withEmptyExcludes = try GlobExpander.collectAllFiles(
            under: dir,
            fileManager: fm,
            excludes: [],
        )
        #expect(withEmptyExcludes == plain)
    }

    @Test
    func dropsExcludeMatchesEarly() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("x", at: "Sources/A.swift", in: dir)
        try write("x", at: ".build/cached.swift", in: dir)
        try write("x", at: "node_modules/lib.swift", in: dir)

        let result = try GlobExpander.collectAllFiles(
            under: dir,
            fileManager: fm,
            excludes: [".build/**", "node_modules/**"],
        )
        #expect(result.contains("Sources/A.swift"))
        #expect(!result.contains(".build/cached.swift"))
        #expect(!result.contains("node_modules/lib.swift"))
    }

    @Test
    func skipsNestedExcludedDirectories() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("x", at: "Sources/A.swift", in: dir)
        try write("x", at: "Packages/Foo/.build/x.o", in: dir)
        try write("x", at: "Packages/Foo/.build/sub/y.o", in: dir)
        try write("x", at: "Packages/Bar/.build/z.o", in: dir)

        let result = try GlobExpander.collectAllFiles(
            under: dir,
            fileManager: fm,
            excludes: ["**/.build/**"],
        )
        #expect(result.contains("Sources/A.swift"))
        #expect(!result.contains { $0.contains(".build/") })
    }

    @Test
    func skipsSymlinkToDirectoryButKeepsSymlinkToFile() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("x", at: "Sources/A.swift", in: dir)
        try fm.createDirectory(at: dir.appending(path: "real_dir"), withIntermediateDirectories: true)
        try write("inside", at: "real_dir/inside.txt", in: dir)
        // dir symlink: must NOT land in the result (otherwise ChecksumCalculator would
        // later treat it as a missing source file).
        try fm.createSymbolicLink(
            at: dir.appending(path: "link_dir"),
            withDestinationURL: dir.appending(path: "real_dir"),
        )
        // file symlink: must remain in the result; matches pre-enumerator behaviour.
        try fm.createSymbolicLink(
            at: dir.appending(path: "link_file"),
            withDestinationURL: dir.appending(path: "Sources/A.swift"),
        )

        let result = try GlobExpander.collectAllFiles(under: dir, fileManager: fm, excludes: [])
        #expect(result.contains("Sources/A.swift"))
        #expect(result.contains("link_file"))
        #expect(!result.contains("link_dir"))
    }

    @Test
    func keepsFilesUnderNonExcludedDirectoriesWithSimilarNames() throws {
        // Guard against accidental over-skipping: `.buildkit` must not be treated as `.build`.
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("x", at: "Sources/A.swift", in: dir)
        try write("x", at: ".build/cached.o", in: dir)
        try write("x", at: ".buildkit/keep.swift", in: dir)

        let result = try GlobExpander.collectAllFiles(
            under: dir,
            fileManager: fm,
            excludes: [".build/**"],
        )
        #expect(result.contains("Sources/A.swift"))
        #expect(result.contains(".buildkit/keep.swift"))
        #expect(!result.contains(".build/cached.o"))
    }
}
