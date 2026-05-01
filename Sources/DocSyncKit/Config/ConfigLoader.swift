import FileManagerProtocol
import Foundation
import Yams

package struct ConfigLoader: Sendable {
    private let fileManager: any FileManagerProtocol

    package init(fileManager: some FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

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

    package func save(_ config: DocSyncConfig, to url: URL) throws {
        let yaml = try YAMLEncoder().encode(config)
        guard let data = yaml.data(using: .utf8) else {
            throw ConfigError.encodingFailed
        }
        try data.write(to: url)
    }
}

package enum ConfigError: LocalizedError, Equatable {
    case fileNotFound(String)
    case invalidEncoding(String)
    case encodingFailed

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
