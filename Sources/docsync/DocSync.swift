import DocSyncCLI

@main
struct DocSync {
    static func main() async throws {
        await DocSyncCommand.main()
    }
}
