import Crypto
import FileManagerProtocol
import Foundation

/// Computes a deterministic SHA-256 checksum over a set of source files.
package enum ChecksumCalculator {
    /// Returns a lowercase hex SHA-256 digest of the concatenated contents of `sources`, sorted alphabetically.
    package static func calculate(
        sources: [String],
        relativeTo base: URL,
        fileManager: some FileManagerProtocol,
    ) throws -> String {
        let sorted = sources.sorted()
        var hasher = SHA256()
        for path in sorted {
            let url = base.appending(path: path)
            let data = fileManager.contents(atPath: url.path(percentEncoded: false))
            guard let data else {
                throw ChecksumError.sourceFileNotFound(url.path(percentEncoded: false))
            }
            hasher.update(data: data)
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

/// Errors thrown by ``ChecksumCalculator``.
package enum ChecksumError: LocalizedError, Equatable {
    case sourceFileNotFound(String)

    /// Human-readable description of the error.
    package var errorDescription: String? {
        switch self {
        case let .sourceFileNotFound(path):
            "Source file not found: \(path)"
        }
    }
}
