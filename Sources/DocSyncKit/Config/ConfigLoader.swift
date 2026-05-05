import FileManagerProtocol
import Foundation
import Yams

/// Loads and saves ``DocSyncConfig`` from/to a YAML file.
package struct ConfigLoader {
    private let fileManager: any FileManagerProtocol

    /// Creates a loader backed by the given file manager.
    package init(fileManager: some FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    /// Reads and decodes ``DocSyncConfig`` from the YAML file at `url`.
    package func load(from url: URL) throws -> DocSyncConfig {
        let data = fileManager.contents(atPath: url.path(percentEncoded: false))
        guard let data else {
            throw ConfigError.fileNotFound(url.path(percentEncoded: false))
        }
        guard let yaml = String(data: data, encoding: .utf8) else {
            throw ConfigError.invalidEncoding(url.path(percentEncoded: false))
        }
        return try YAMLDecoder().decode(DocSyncConfig.self, from: yaml)
    }

    /// Encodes `config` as YAML and writes it to `url`.
    package func save(_ config: DocSyncConfig, to url: URL) throws {
        let encoder = YAMLEncoder()
        // allow_unicode=true: non-ASCII characters (e.g. Japanese) are written as-is
        // instead of \uXXXX escape sequences
        encoder.options.allowUnicode = true
        let yaml = try encoder.encode(config)
        guard let data = yaml.data(using: .utf8) else {
            throw ConfigError.encodingFailed
        }
        try data.write(to: url)
    }
}

/// Errors thrown by ``ConfigLoader``.
package enum ConfigError: LocalizedError, Equatable {
    case fileNotFound(String)
    case invalidEncoding(String)
    case encodingFailed

    /// Human-readable description of the error.
    package var errorDescription: String? {
        switch self {
        case let .fileNotFound(path):
            "Config file not found: \(path)"
        case let .invalidEncoding(path):
            "Config file is not valid UTF-8: \(path)"
        case .encodingFailed:
            "Failed to encode config as UTF-8"
        }
    }
}
