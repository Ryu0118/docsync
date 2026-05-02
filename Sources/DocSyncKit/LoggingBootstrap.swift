import Logging

/// Bootstraps the swift-log system with ``DocSyncLogHandler``.
package enum LoggingBootstrap {
    /// Installs ``DocSyncLogHandler`` as the global log handler. Call once at process startup.
    package static func bootstrap() {
        LoggingSystem.bootstrap { label in
            DocSyncLogHandler(label: label, metadataProvider: nil)
        }
    }
}
