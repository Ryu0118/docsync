import DocSyncCLI
import DocSyncKit

@main
struct DocSync {
    static func main() async throws {
        LoggingBootstrap.bootstrap()
        await DocSyncCommand.main()
    }
}
