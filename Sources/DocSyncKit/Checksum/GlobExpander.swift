import FileManagerProtocol
import Foundation

/// Expands glob patterns in source lists to concrete file paths.
///
/// Supported syntax:
/// - Literal paths: `Sources/Foo/Bar.swift`
/// - `*` — matches any sequence of characters within a single path component (e.g. `Sources/Rules/*Rule.swift`)
/// - `**` — matches zero or more path components recursively (e.g. `Sources/**/*.swift`)
package enum GlobExpander {
    /// Expands `patterns` relative to `base`, returning a sorted, deduplicated list of file paths.
    ///
    /// Patterns without wildcards are returned as-is (existence is validated by ``ChecksumCalculator``).
    /// Glob patterns that match zero files throw ``ChecksumError/noGlobMatches(_:)``.
    package static func expand(
        patterns: [String],
        relativeTo base: URL,
        fileManager: some FileManagerProtocol,
    ) throws -> [String] {
        var result: [String] = []
        for pattern in patterns {
            try appendExpanded(pattern: pattern, base: base, fileManager: fileManager, into: &result)
        }
        return Array(Set(result)).sorted()
    }

    /// Returns true if `path` matches the glob `pattern`.
    ///
    /// `**` matches zero or more path components; `*` matches within a single component; `?` matches one character.
    package static func matchesGlob(pattern: String, path: String) -> Bool {
        matchGlob(pattern: Array(pattern), patternIndex: 0, path: Array(path), pathIndex: 0)
    }

    private static func appendExpanded(
        pattern: String,
        base: URL,
        fileManager: some FileManagerProtocol,
        into result: inout [String],
    ) throws {
        if isGlob(pattern) {
            let matched = try expandGlob(pattern, base: base, fileManager: fileManager)
            guard !matched.isEmpty else { throw ChecksumError.noGlobMatches(pattern) }
            result.append(contentsOf: matched)
        } else {
            result.append(pattern)
        }
    }

    private static func isGlob(_ pattern: String) -> Bool {
        pattern.contains("*") || pattern.contains("?")
    }

    private static func expandGlob(
        _ pattern: String,
        base: URL,
        fileManager: some FileManagerProtocol,
    ) throws -> [String] {
        let allFiles = try collectAllFiles(under: base, fileManager: fileManager)
        return allFiles.filter { matchesGlob(pattern: pattern, path: $0) }.sorted()
    }

    private static func collectAllFiles(
        under base: URL,
        fileManager: some FileManagerProtocol,
    ) throws -> [String] {
        guard let subpaths = fileManager.subpaths(atPath: base.path(percentEncoded: false)) else {
            return []
        }
        return subpaths.filter { isFile(path: $0, base: base, fileManager: fileManager) }
    }

    private static func isFile(path: String, base: URL, fileManager: some FileManagerProtocol) -> Bool {
        var isDir: ObjCBool = false
        let full = base.appending(path: path).path(percentEncoded: false)
        fileManager.fileExists(atPath: full, isDirectory: &isDir)
        return !isDir.boolValue
    }

    private static func matchGlob(
        pattern: [Character],
        patternIndex: Int,
        path: [Character],
        pathIndex: Int,
    ) -> Bool {
        var patIdx = patternIndex
        var pathIdx = pathIndex

        while patIdx < pattern.count {
            let char = pattern[patIdx]
            if char == "*" {
                return matchStar(pattern: pattern, patternIndex: patIdx, path: path, pathIndex: pathIdx)
            }
            guard let next = advanceLiteral(char: char, patIdx: &patIdx, pathIdx: &pathIdx, path: path) else {
                return false
            }
            _ = next
        }
        return pathIdx == path.count
    }

    /// Advances `patIdx` and `pathIdx` by one for `?` or a literal character match.
    /// Returns `true` on success, `nil` (false) if the match fails.
    private static func advanceLiteral(
        char: Character,
        patIdx: inout Int,
        pathIdx: inout Int,
        path: [Character],
    ) -> Bool? {
        if char == "?" {
            guard pathIdx < path.count, path[pathIdx] != "/" else { return nil }
        } else {
            guard pathIdx < path.count, char == path[pathIdx] else { return nil }
        }
        patIdx += 1
        pathIdx += 1
        return true
    }

    private static func matchStar(
        pattern: [Character],
        patternIndex: Int,
        path: [Character],
        pathIndex: Int,
    ) -> Bool {
        let isDoublestar = patternIndex + 1 < pattern.count && pattern[patternIndex + 1] == "*"
        return if isDoublestar {
            matchDoublestar(pattern: pattern, patternIndex: patternIndex, path: path, pathIndex: pathIndex)
        } else {
            matchSinglestar(pattern: pattern, patternIndex: patternIndex, path: path, pathIndex: pathIndex)
        }
    }

    private static func matchDoublestar(
        pattern: [Character],
        patternIndex: Int,
        path: [Character],
        pathIndex: Int,
    ) -> Bool {
        var nextPatIdx = patternIndex + 2
        if nextPatIdx < pattern.count, pattern[nextPatIdx] == "/" {
            nextPatIdx += 1
        }
        var tryPathIdx = pathIndex
        while true {
            if matchGlob(pattern: pattern, patternIndex: nextPatIdx, path: path, pathIndex: tryPathIdx) {
                return true
            }
            if tryPathIdx >= path.count { break }
            tryPathIdx += 1
        }
        return false
    }

    private static func matchSinglestar(
        pattern: [Character],
        patternIndex: Int,
        path: [Character],
        pathIndex: Int,
    ) -> Bool {
        let nextPatIdx = patternIndex + 1
        var tryPathIdx = pathIndex
        while tryPathIdx < path.count, path[tryPathIdx] != "/" {
            if matchGlob(pattern: pattern, patternIndex: nextPatIdx, path: path, pathIndex: tryPathIdx) {
                return true
            }
            tryPathIdx += 1
        }
        return matchGlob(pattern: pattern, patternIndex: nextPatIdx, path: path, pathIndex: tryPathIdx)
    }
}
