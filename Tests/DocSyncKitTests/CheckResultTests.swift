// swiftformat:disable redundantSwiftTestingSuite
@testable import DocSyncKit
import Testing

@Suite
struct CheckResultTests {
    @Test
    func `all in sync true when all in sync`() {
        let result = CheckResult(statuses: [
            .inSync(ruleName: "r1"),
            .inSync(ruleName: "r2"),
        ])
        #expect(result.allInSync)
    }

    @Test
    func `all in sync false when out of sync`() {
        let result = CheckResult(statuses: [
            .inSync(ruleName: "r1"),
            .outOfSync(ruleName: "r2", doc: "d.md", message: nil),
        ])
        #expect(!result.allInSync)
    }

    @Test
    func `all in sync false when missing checksum`() {
        let result = CheckResult(statuses: [
            .missingChecksum(ruleName: "r1"),
        ])
        #expect(!result.allInSync)
    }

    @Test
    func `all in sync true for empty statuses`() {
        let result = CheckResult(statuses: [])
        #expect(result.allInSync)
    }

    @Test
    func `rule name returns correct name for each case`() {
        #expect(RuleStatus.inSync(ruleName: "alpha").ruleName == "alpha")
        #expect(RuleStatus.outOfSync(ruleName: "beta", doc: "d.md", message: nil).ruleName == "beta")
        #expect(RuleStatus.missingChecksum(ruleName: "gamma").ruleName == "gamma")
    }

    @Test
    func `is in sync returns correct value`() {
        #expect(RuleStatus.inSync(ruleName: "r").isInSync)
        #expect(!RuleStatus.outOfSync(ruleName: "r", doc: "d.md", message: nil).isInSync)
        #expect(!RuleStatus.missingChecksum(ruleName: "r").isInSync)
    }

    @Test
    func `rule status equality`() {
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
    func `claudeHookOutput is nil when all in sync`() {
        let result = CheckResult(statuses: [.inSync(ruleName: "r1"), .inSync(ruleName: "r2")])
        #expect(result.claudeHookOutput == nil)
    }

    @Test
    func `claudeHookOutput is nil for empty statuses`() {
        let result = CheckResult(statuses: [])
        #expect(result.claudeHookOutput == nil)
    }

    @Test
    func `claudeHookOutput blocks when outOfSync with default message`() {
        let result = CheckResult(statuses: [.outOfSync(ruleName: "api-doc", doc: "docs/api.md", message: nil)])
        let output = result.claudeHookOutput
        #expect(output != nil)
        #expect(output?.decision == "block")
        #expect(output?.reason.contains("api-doc") == true)
        #expect(output?.reason.contains("docs/api.md") == true)
        #expect(output?.reason.contains("docsync update-checksum") == true)
    }

    @Test
    func `claudeHookOutput blocks when outOfSync with custom message`() {
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
    func `claudeHookOutput blocks when missingChecksum`() {
        let result = CheckResult(statuses: [.missingChecksum(ruleName: "guide")])
        let output = result.claudeHookOutput
        #expect(output != nil)
        #expect(output?.decision == "block")
        #expect(output?.reason.contains("guide") == true)
        #expect(output?.reason.contains("docsync update-checksum") == true)
    }

    @Test
    func `claudeHookOutput aggregates multiple failures`() {
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
    func `codexHookOutput is nil when all in sync`() {
        let result = CheckResult(statuses: [.inSync(ruleName: "r1")])
        #expect(result.codexHookOutput == nil)
    }

    @Test
    func `codexHookOutput blocks when outOfSync`() {
        let result = CheckResult(statuses: [.outOfSync(ruleName: "api-doc", doc: "docs/api.md", message: nil)])
        let output = result.codexHookOutput
        #expect(output != nil)
        #expect(output?.decision == "block")
        #expect(output?.reason.contains("api-doc") == true)
        #expect(output?.reason.contains("docs/api.md") == true)
    }

    @Test
    func `codexHookOutput and claudeHookOutput produce same payload`() {
        let result = CheckResult(statuses: [.outOfSync(ruleName: "r", doc: "d.md", message: "Update it")])
        #expect(result.codexHookOutput == result.claudeHookOutput)
    }
}
