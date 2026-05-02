import Foundation

/// Resolves a config file path string to an absolute URL.
package enum ConfigURL {
    /// Returns an absolute URL for the given path, resolving relative paths against the current directory.
    package static func resolved(from path: String) -> URL {
        if path.hasPrefix("/") {
            return URL(filePath: path)
        }
        return URL(filePath: FileManager.default.currentDirectoryPath)
            .appending(path: path)
    }
}
