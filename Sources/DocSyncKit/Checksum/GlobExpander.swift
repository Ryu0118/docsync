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
        try expand(
            patterns: patterns,
            excludes: [],
            relativeTo: base,
            fileManager: fileManager,
            cachedAllFiles: nil,
        )
    }

    /// Expands `patterns` while removing any glob-matched paths covered by `excludes`.
    ///
    /// Literal (non-glob) entries in `patterns` bypass `excludes` so explicit user intent
    /// always wins. `cachedAllFiles` lets callers reuse a single directory enumeration
    /// across multiple `expand` invocations sharing the same `base`.
    package static func expand(
        patterns: [String],
        excludes: [String],
        relativeTo base: URL,
        fileManager: some FileManagerProtocol,
        cachedAllFiles: [String]?,
    ) throws -> [String] {
        let lazyAllFiles = LazyThrowing<[String]> {
            // When the caller passes cachedAllFiles we cannot know whether they pre-applied
            // excludes, so we re-apply here defensively. The cache-less path delegates to
            // the excludes-aware collectAllFiles so that subpath entries matching excludes
            // are dropped *before* the expensive per-path fileExists check runs.
            if let cachedAllFiles {
                return excludes.isEmpty
                    ? cachedAllFiles
                    : cachedAllFiles.filter { path in !excludes.contains { matchesGlob(pattern: $0, path: path) } }
            }
            return try collectAllFiles(under: base, fileManager: fileManager, excludes: excludes)
        }
        let expanded = try patterns.flatMap { pattern -> [String] in
            guard isGlob(pattern) else { return [pattern] }
            let matched = try lazyAllFiles.value().filter { matchesGlob(pattern: pattern, path: $0) }
            guard !matched.isEmpty else { throw ChecksumError.noGlobMatches(pattern) }
            return matched
        }
        return Array(Set(expanded)).sorted()
    }

    /// Enumerates every file (not directory) under `base`. Exposed for callers that want to
    /// reuse the result across multiple ``expand(patterns:relativeTo:fileManager:cachedAllFiles:)`` calls.
    package static func collectAllFiles(
        under base: URL,
        fileManager: some FileManagerProtocol,
    ) throws -> [String] {
        try collectAllFiles(under: base, fileManager: fileManager, excludes: [])
    }

    /// Enumerates every file under `base` while dropping `excludes`-matched paths *before*
    /// the per-path `fileExists` check runs.
    ///
    /// On large trees the `fileExists` calls dominate `collectAllFiles`. Filtering
    /// `subpaths` against `excludes` first removes the cost of those calls for every
    /// excluded file, not just the cost of glob matching.
    package static func collectAllFiles(
        under base: URL,
        fileManager: some FileManagerProtocol,
        excludes: [String],
    ) throws -> [String] {
        guard let subpaths = fileManager.subpaths(atPath: base.path(percentEncoded: false)) else {
            return []
        }
        let candidates = excludes.isEmpty
            ? subpaths
            : subpaths.filter { path in !excludes.contains { matchesGlob(pattern: $0, path: path) } }
        return candidates.filter { isFile(path: $0, base: base, fileManager: fileManager) }
    }

    /// Returns true if `path` matches the glob `pattern`.
    ///
    /// `**` matches zero or more path components; `*` matches within a single component; `?` matches one character.
    package static func matchesGlob(pattern: String, path: String) -> Bool {
        matchGlob(pattern: Array(pattern), patternIndex: 0, path: Array(path), pathIndex: 0)
    }

    private static func isGlob(_ pattern: String) -> Bool {
        pattern.contains("*") || pattern.contains("?")
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
