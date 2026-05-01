import Testing

@testable import DocSyncKit

@Suite("CheckResult")
struct CheckResultTests {
    @Test("allInSync is true when all statuses are inSync")
    func allInSyncTrue() {
        let result = CheckResult(statuses: [
            .inSync(ruleName: "r1"),
            .inSync(ruleName: "r2"),
        ])
        #expect(result.allInSync)
    }

    @Test("allInSync is false when any status is outOfSync")
    func allInSyncFalseOutOfSync() {
        let result = CheckResult(statuses: [
            .inSync(ruleName: "r1"),
            .outOfSync(ruleName: "r2", doc: "d.md"),
        ])
        #expect(!result.allInSync)
    }

    @Test("allInSync is false when any status is missingChecksum")
    func allInSyncFalseMissingChecksum() {
        let result = CheckResult(statuses: [
            .missingChecksum(ruleName: "r1"),
        ])
        #expect(!result.allInSync)
    }

    @Test("allInSync is true for empty statuses")
    func emptyStatuses() {
        let result = CheckResult(statuses: [])
        #expect(result.allInSync)
    }

    @Test("RuleStatus.ruleName returns correct name for each case")
    func ruleNames() {
        #expect(RuleStatus.inSync(ruleName: "alpha").ruleName == "alpha")
        #expect(RuleStatus.outOfSync(ruleName: "beta", doc: "d.md").ruleName == "beta")
        #expect(RuleStatus.missingChecksum(ruleName: "gamma").ruleName == "gamma")
    }

    @Test("RuleStatus.isInSync returns correct value")
    func isInSync() {
        #expect(RuleStatus.inSync(ruleName: "r").isInSync)
        #expect(!RuleStatus.outOfSync(ruleName: "r", doc: "d.md").isInSync)
        #expect(!RuleStatus.missingChecksum(ruleName: "r").isInSync)
    }

    @Test("RuleStatus equality")
    func equality() {
        #expect(RuleStatus.inSync(ruleName: "r") == RuleStatus.inSync(ruleName: "r"))
        #expect(RuleStatus.outOfSync(ruleName: "r", doc: "d.md") == RuleStatus.outOfSync(ruleName: "r", doc: "d.md"))
        #expect(RuleStatus.inSync(ruleName: "r") != RuleStatus.outOfSync(ruleName: "r", doc: "d.md"))
    }
}
