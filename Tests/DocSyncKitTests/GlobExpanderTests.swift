// swiftformat:disable redundantSwiftTestingSuite
@testable import DocSyncKit
import Foundation
import Testing

@Suite
struct GlobExpanderTests {
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

    // MARK: - matchesGlob

    @Test
    func literalPathMatchesExactly() {
        #expect(GlobExpander.matchesGlob(pattern: "Sources/Foo.swift", path: "Sources/Foo.swift"))
        #expect(!GlobExpander.matchesGlob(pattern: "Sources/Foo.swift", path: "Sources/Bar.swift"))
    }

    @Test
    func singleStarMatchesWithinOneComponent() {
        let pat = "Sources/Rules/*Rule.swift"
        #expect(GlobExpander.matchesGlob(pattern: pat, path: "Sources/Rules/DeepNestingRule.swift"))
        #expect(GlobExpander.matchesGlob(pattern: pat, path: "Sources/Rules/MissingDocsRule.swift"))
        #expect(!GlobExpander.matchesGlob(pattern: pat, path: "Sources/Other/DeepNestingRule.swift"))
    }

    @Test
    func singleStarDoesNotCrossDirectoryBoundary() {
        #expect(!GlobExpander.matchesGlob(pattern: "Sources/*.swift", path: "Sources/Sub/Foo.swift"))
    }

    @Test
    func doubleStarMatchesAcrossDirectories() {
        #expect(GlobExpander.matchesGlob(pattern: "Sources/**/*.swift", path: "Sources/Foo.swift"))
        #expect(GlobExpander.matchesGlob(pattern: "Sources/**/*.swift", path: "Sources/Sub/Foo.swift"))
        #expect(GlobExpander.matchesGlob(pattern: "Sources/**/*.swift", path: "Sources/A/B/C/Foo.swift"))
        #expect(!GlobExpander.matchesGlob(pattern: "Sources/**/*.swift", path: "Tests/Sub/FooTests.swift"))
    }

    @Test
    func doubleStarWithNoSubdirectory() {
        #expect(GlobExpander.matchesGlob(pattern: "Sources/**/Foo.swift", path: "Sources/Foo.swift"))
    }

    @Test
    func questionMarkMatchesSingleNonSlashCharacter() {
        #expect(GlobExpander.matchesGlob(pattern: "src/?.swift", path: "src/A.swift"))
        #expect(!GlobExpander.matchesGlob(pattern: "src/?.swift", path: "src/AB.swift"))
        #expect(!GlobExpander.matchesGlob(pattern: "src/?.swift", path: "src/a/B.swift"))
    }

    // MARK: - expand

    @Test
    func literalPathsAreReturnedAsIs() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("x", at: "a.swift", in: dir)

        let result = try GlobExpander.expand(patterns: ["a.swift"], relativeTo: dir, fileManager: fm)
        #expect(result == ["a.swift"])
    }

    @Test
    func globExpandsToMatchingFilesSorted() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("x", at: "Sources/Rules/ARule.swift", in: dir)
        try write("x", at: "Sources/Rules/BRule.swift", in: dir)
        try write("x", at: "Sources/Rules/Helper.swift", in: dir)

        let result = try GlobExpander.expand(
            patterns: ["Sources/Rules/*Rule.swift"],
            relativeTo: dir,
            fileManager: fm,
        )
        #expect(result == ["Sources/Rules/ARule.swift", "Sources/Rules/BRule.swift"])
    }

    @Test
    func doubleStarGlobExpandsRecursively() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("x", at: "Sources/A.swift", in: dir)
        try write("x", at: "Sources/Sub/B.swift", in: dir)
        try write("x", at: "Sources/Sub/Deep/C.swift", in: dir)
        try write("x", at: "Tests/T.swift", in: dir)

        let result = try GlobExpander.expand(
            patterns: ["Sources/**/*.swift"],
            relativeTo: dir,
            fileManager: fm,
        )
        #expect(result == ["Sources/A.swift", "Sources/Sub/B.swift", "Sources/Sub/Deep/C.swift"])
    }

    @Test
    func globWithNoMatchesThrowsNoGlobMatches() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }

        #expect(throws: ChecksumError.noGlobMatches("Sources/*.swift")) {
            try GlobExpander.expand(patterns: ["Sources/*.swift"], relativeTo: dir, fileManager: fm)
        }
    }

    @Test
    func duplicatesAcrossPatternsAreDeduplicated() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("x", at: "Sources/Foo.swift", in: dir)

        let result = try GlobExpander.expand(
            patterns: ["Sources/Foo.swift", "Sources/Foo.swift"],
            relativeTo: dir,
            fileManager: fm,
        )
        #expect(result == ["Sources/Foo.swift"])
    }

    struct CacheCase: CustomTestStringConvertible {
        let label: String
        let patterns: [String]
        let useCache: Bool
        let expectedResult: [String]
        var testDescription: String {
            label
        }
    }

    @Test(arguments: [
        CacheCase(
            label: "cached_allFiles_produces_same_result",
            patterns: ["Sources/*.swift"],
            useCache: true,
            expectedResult: ["Sources/A.swift", "Sources/B.swift", "Sources/C.swift"],
        ),
        CacheCase(
            label: "uncached_handles_duplicate_globs",
            patterns: ["Sources/*.swift", "Sources/A.swift", "Sources/*.swift"],
            useCache: false,
            expectedResult: ["Sources/A.swift", "Sources/B.swift", "Sources/C.swift"],
        ),
    ])
    func expandHonoursCachedAllFiles(_ testCase: CacheCase) throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("x", at: "Sources/A.swift", in: dir)
        try write("x", at: "Sources/B.swift", in: dir)
        try write("x", at: "Sources/C.swift", in: dir)

        let cached = testCase.useCache
            ? try GlobExpander.collectAllFiles(under: dir, fileManager: fm)
            : nil

        let result = try GlobExpander.expand(
            patterns: testCase.patterns,
            relativeTo: dir,
            fileManager: fm,
            cachedAllFiles: cached,
        )

        #expect(result == testCase.expectedResult)
    }

    @Test
    func mixedLiteralAndGlobPatterns() throws {
        let dir = try makeTempDir()
        defer { try? fm.removeItem(at: dir) }
        try write("x", at: "Package.swift", in: dir)
        try write("x", at: "Sources/ARule.swift", in: dir)
        try write("x", at: "Sources/BRule.swift", in: dir)

        let result = try GlobExpander.expand(
            patterns: ["Package.swift", "Sources/*Rule.swift"],
            relativeTo: dir,
            fileManager: fm,
        )
        #expect(result == ["Package.swift", "Sources/ARule.swift", "Sources/BRule.swift"])
    }
}
