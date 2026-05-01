import Foundation
import Logging

package struct DocSyncLogHandler: LogHandler {
    package static let plainOutputMetadataKey = "docsync_output"
    package static let plainOutputMetadataValue = "plain"
    package static let stdoutOutputMetadataKey = "docsync_stdout"
    package static let stdoutOutputMetadataValue = "stdout"

    private var handler: StreamLogHandler

    package init(label: String, metadataProvider: Logger.MetadataProvider?) {
        handler = StreamLogHandler.standardError(label: label, metadataProvider: metadataProvider)
    }

    package var logLevel: Logger.Level {
        get { handler.logLevel }
        set { handler.logLevel = newValue }
    }

    package var metadataProvider: Logger.MetadataProvider? {
        get { handler.metadataProvider }
        set { handler.metadataProvider = newValue }
    }

    package var metadata: Logger.Metadata {
        get { handler.metadata }
        set { handler.metadata = newValue }
    }

    package subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { handler[metadataKey: metadataKey] }
        set { handler[metadataKey: metadataKey] = newValue }
    }

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
    static let plainOutput: Self = [
        DocSyncLogHandler.plainOutputMetadataKey: .string(DocSyncLogHandler.plainOutputMetadataValue),
    ]

    static let stdoutOutput: Self = [
        DocSyncLogHandler.stdoutOutputMetadataKey: .string(DocSyncLogHandler.stdoutOutputMetadataValue),
    ]
}
