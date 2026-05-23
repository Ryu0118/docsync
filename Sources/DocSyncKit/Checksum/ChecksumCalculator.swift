import Crypto
import FileManagerProtocol
import Foundation

/// Computes a deterministic SHA-256 checksum over a set of source files.
package enum ChecksumCalculator {
    /// Returns a lowercase hex SHA-256 digest over the resolved sources.
    ///
    /// Sources are sorted alphabetically after glob expansion. Each file contributes
    /// its relative path (UTF-8, null-terminated) followed by its contents to the hash,
    /// so adding or renaming a file changes the checksum even if contents are identical.
    package static func calculate(
        sources: [String],
        relativeTo base: URL,
        fileManager: some FileManagerProtocol,
    ) throws -> String {
        try calculate(
            sources: sources,
            excludes: [],
            relativeTo: base,
            fileManager: fileManager,
            cachedAllFiles: nil,
        )
    }

    /// Accepts top-level `excludes` and an optional `cachedAllFiles` to amortise directory
    /// enumeration across rules. Literal entries in `sources` bypass `excludes`.
    package static func calculate(
        sources: [String],
        excludes: [String],
        relativeTo base: URL,
        fileManager: some FileManagerProtocol,
        cachedAllFiles: [String]?,
    ) throws -> String {
        let resolved = try GlobExpander.expand(
            patterns: sources,
            excludes: excludes,
            relativeTo: base,
            fileManager: fileManager,
            cachedAllFiles: cachedAllFiles,
        )
        let hasher = try resolved.reduce(into: SHA256()) { hasher, path in
            let url = base.appending(path: path)
            guard let data = fileManager.contents(atPath: url.path(percentEncoded: false)) else {
                throw ChecksumError.sourceFileNotFound(url.path(percentEncoded: false))
            }
            hasher.update(data: Data(path.utf8))
            hasher.update(data: Data([0x00]))
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

/// Errors thrown by ``ChecksumCalculator`` and ``GlobExpander``.
package enum ChecksumError: LocalizedError, Equatable {
    case sourceFileNotFound(String)
    case noGlobMatches(String)

    /// Human-readable description of the error.
    package var errorDescription: String? {
        switch self {
        case let .sourceFileNotFound(path):
            "Source file not found: \(path)"
        case let .noGlobMatches(pattern):
            "Glob pattern matched no files: \(pattern)"
        }
    }
}
