// swiftformat:disable redundantSwiftTestingSuite
@testable import DocSyncKit
import Testing

@Suite
struct CheckResultTests {
    @Test
    func allInSyncTrueWhenAllInSync() {
        let result = CheckResult(statuses: [
            .inSync(ruleName: "r1"),
            .inSync(ruleName: "r2"),
        ])
        #expect(result.allInSync)
    }

    @Test
    func allInSyncFalseWhenOutOfSync() {
        let result = CheckResult(statuses: [
            .inSync(ruleName: "r1"),
            .outOfSync(ruleName: "r2", doc: "d.md", message: nil),
        ])
        #expect(!result.allInSync)
    }

    @Test
    func allInSyncFalseWhenMissingChecksum() {
        let result = CheckResult(statuses: [
            .missingChecksum(ruleName: "r1"),
        ])
        #expect(!result.allInSync)
    }

    @Test
    func allInSyncTrueForEmptyStatuses() {
        let result = CheckResult(statuses: [])
        #expect(result.allInSync)
    }

    @Test
    func ruleNameReturnsCorrectNameForEachCase() {
        #expect(RuleStatus.inSync(ruleName: "alpha").ruleName == "alpha")
        #expect(RuleStatus.outOfSync(ruleName: "beta", doc: "d.md", message: nil).ruleName == "beta")
        #expect(RuleStatus.missingChecksum(ruleName: "gamma").ruleName == "gamma")
    }

    @Test
    func isInSyncReturnsCorrectValue() {
        #expect(RuleStatus.inSync(ruleName: "r").isInSync)
        #expect(!RuleStatus.outOfSync(ruleName: "r", doc: "d.md", message: nil).isInSync)
        #expect(!RuleStatus.missingChecksum(ruleName: "r").isInSync)
    }

    @Test
    func ruleStatusEquality() {
        #expect(RuleStatus.inSync(ruleName: "r") == RuleStatus.inSync(ruleName: "r"))
        #expect(
            RuleStatus.outOfSync(ruleName: "r", doc: "d.md", message: nil) ==
                RuleStatus.outOfSync(ruleName: "r", doc: "d.md", message: nil),
        )
        #expect(
            RuleStatus.inSync(ruleName: "r") !=
                RuleStatus.outOfSync(ruleName: "r", doc: "d.md", message: nil),
        )
    }

    @Test
    func claudeHookOutputIsNilWhenAllInSync() {
        let result = CheckResult(statuses: [.inSync(ruleName: "r1"), .inSync(ruleName: "r2")])
        #expect(result.claudeHookOutput == nil)
    }

    @Test
    func claudeHookOutputIsNilForEmptyStatuses() {
        let result = CheckResult(statuses: [])
        #expect(result.claudeHookOutput == nil)
    }

    @Test
    func claudeHookOutputBlocksWhenOutOfSyncWithDefaultMessage() {
        let result = CheckResult(statuses: [.outOfSync(ruleName: "api-doc", doc: "docs/api.md", message: nil)])
        let output = result.claudeHookOutput
        #expect(output != nil)
        #expect(output?.decision == "block")
        #expect(output?.reason.contains("api-doc") == true)
        #expect(output?.reason.contains("docs/api.md") == true)
        #expect(output?.reason.contains("docsync update-checksum") == true)
    }

    @Test
    func claudeHookOutputBlocksWhenOutOfSyncWithCustomMessage() {
        let result = CheckResult(statuses: [
            .outOfSync(ruleName: "api-doc", doc: "docs/api.md", message: "Update the API reference"),
        ])
        let output = result.claudeHookOutput
        #expect(output != nil)
        #expect(output?.decision == "block")
        #expect(output?.reason.contains("api-doc") == true)
        #expect(output?.reason.contains("Update the API reference") == true)
        #expect(output?.reason.contains("docsync update-checksum") == true)
    }

    @Test
    func claudeHookOutputBlocksWhenMissingChecksum() {
        let result = CheckResult(statuses: [.missingChecksum(ruleName: "guide")])
        let output = result.claudeHookOutput
        #expect(output != nil)
        #expect(output?.decision == "block")
        #expect(output?.reason.contains("guide") == true)
        #expect(output?.reason.contains("docsync update-checksum") == true)
    }

    @Test
    func claudeHookOutputAggregatesMultipleFailures() {
        let result = CheckResult(statuses: [
            .outOfSync(ruleName: "api-doc", doc: "docs/api.md", message: nil),
            .missingChecksum(ruleName: "guide"),
            .inSync(ruleName: "intro"),
        ])
        let output = result.claudeHookOutput
        #expect(output != nil)
        #expect(output?.reason.contains("api-doc") == true)
        #expect(output?.reason.contains("guide") == true)
        #expect(output?.reason.contains("intro") == false)
    }

    @Test
    func codexHookOutputIsNilWhenAllInSync() {
        let result = CheckResult(statuses: [.inSync(ruleName: "r1")])
        #expect(result.codexHookOutput == nil)
    }

    @Test
    func codexHookOutputBlocksWhenOutOfSync() {
        let result = CheckResult(statuses: [.outOfSync(ruleName: "api-doc", doc: "docs/api.md", message: nil)])
        let output = result.codexHookOutput
        #expect(output != nil)
        #expect(output?.decision == "block")
        #expect(output?.reason.contains("api-doc") == true)
        #expect(output?.reason.contains("docs/api.md") == true)
    }

    @Test
    func codexHookOutputAndClaudeHookOutputProduceSamePayload() {
        let result = CheckResult(statuses: [.outOfSync(ruleName: "r", doc: "d.md", message: "Update it")])
        #expect(result.codexHookOutput == result.claudeHookOutput)
    }
}
