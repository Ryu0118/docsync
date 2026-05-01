import Logging

package enum LoggingBootstrap {
    package static func bootstrap() {
        LoggingSystem.bootstrap { label in
            DocSyncLogHandler(label: label, metadataProvider: nil)
        }
    }
}
