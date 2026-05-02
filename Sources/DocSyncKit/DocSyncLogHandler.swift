import Foundation
import Logging

/// A `LogHandler` that routes docsync-specific metadata keys to plain stderr or stdout.
package struct DocSyncLogHandler: LogHandler {
    /// Metadata key used to request plain (unformatted) stderr output.
    package static let plainOutputMetadataKey = "docsync_output"
    /// Metadata value that activates plain stderr output.
    package static let plainOutputMetadataValue = "plain"
    /// Metadata key used to request plain stdout output.
    package static let stdoutOutputMetadataKey = "docsync_stdout"
    /// Metadata value that activates plain stdout output.
    package static let stdoutOutputMetadataValue = "stdout"

    private var handler: StreamLogHandler

    /// Creates a handler that wraps a `StreamLogHandler` writing to stderr.
    package init(label: String, metadataProvider: Logger.MetadataProvider?) {
        handler = StreamLogHandler.standardError(label: label, metadataProvider: metadataProvider)
    }

    /// The minimum log level forwarded to the underlying handler.
    package var logLevel: Logger.Level {
        get { handler.logLevel }
        set { handler.logLevel = newValue }
    }

    /// The metadata provider attached to this handler.
    package var metadataProvider: Logger.MetadataProvider? {
        get { handler.metadataProvider }
        set { handler.metadataProvider = newValue }
    }

    /// The metadata dictionary attached to this handler.
    package var metadata: Logger.Metadata {
        get { handler.metadata }
        set { handler.metadata = newValue }
    }

    /// Accesses individual metadata values by key.
    package subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { handler[metadataKey: metadataKey] }
        set { handler[metadataKey: metadataKey] = newValue }
    }

    /// Logs the event, routing to stdout/stderr/handler based on metadata.
    package func log(event: LogEvent) {
        if Self.shouldEmitStdoutMessage(event.metadata) {
            Self.writeStdoutMessage(event.message.description)
            return
        }

        if Self.shouldEmitPlainMessage(event.metadata) {
            Self.writePlainMessage(event.message.description)
            return
        }

        handler.log(event: event)
    }

    private static func shouldEmitPlainMessage(_ metadata: Logger.Metadata?) -> Bool {
        matches(metadata, key: plainOutputMetadataKey, value: plainOutputMetadataValue)
    }

    private static func shouldEmitStdoutMessage(_ metadata: Logger.Metadata?) -> Bool {
        matches(metadata, key: stdoutOutputMetadataKey, value: stdoutOutputMetadataValue)
    }

    private static func matches(_ metadata: Logger.Metadata?, key: String, value: String) -> Bool {
        guard let entry = metadata?[key] else { return false }
        switch entry {
        case let .string(string): return string == value
        case let .stringConvertible(stringConvertible): return stringConvertible.description == value
        default: return false
        }
    }

    private static func writePlainMessage(_ message: String) {
        FileHandle.standardError.write(Data("\(message)\n".utf8))
    }

    private static func writeStdoutMessage(_ message: String) {
        FileHandle.standardOutput.write(Data("\(message)\n".utf8))
    }
}

package extension Logger.Metadata {
    /// Metadata that routes log output to plain stderr.
    static let plainOutput: Self = [
        DocSyncLogHandler.plainOutputMetadataKey: .string(DocSyncLogHandler.plainOutputMetadataValue),
    ]

    /// Metadata that routes log output to plain stdout.
    static let stdoutOutput: Self = [
        DocSyncLogHandler.stdoutOutputMetadataKey: .string(DocSyncLogHandler.stdoutOutputMetadataValue),
    ]
}
