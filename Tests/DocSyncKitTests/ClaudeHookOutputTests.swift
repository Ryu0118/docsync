// swiftformat:disable redundantSwiftTestingSuite
@testable import DocSyncKit
import Foundation
import Testing

@Suite
struct ClaudeHookOutputTests {
    @Test
    func decisionIsAlwaysBlock() {
        let output = ClaudeHookOutput(reason: "anything")
        #expect(output.decision == "block")
    }

    @Test
    func jsonStringReturnsBlockDecisionWithReason() {
        let output = ClaudeHookOutput(reason: "Docs out of sync.")
        #expect(output.jsonString == "{\"decision\":\"block\",\"reason\":\"Docs out of sync.\"}")
    }

    @Test
    func jsonStringEscapesDoubleQuotesInReason() throws {
        let message = #"Stop: "update" docs"#
        let output = ClaudeHookOutput(reason: message)
        let data = Data(output.jsonString.utf8)
        let decoded = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(decoded["decision"] == "block")
        #expect(decoded["reason"] == message)
    }

    @Test
    func jsonStringEscapesBackslashesInReason() throws {
        let message = #"path\to\file"#
        let output = ClaudeHookOutput(reason: message)
        let data = Data(output.jsonString.utf8)
        let decoded = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(decoded["reason"] == message)
    }

    @Test
    func jsonStringEscapesNewlinesInReason() throws {
        let message = "line1\nline2"
        let output = ClaudeHookOutput(reason: message)
        let data = Data(output.jsonString.utf8)
        let decoded = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(decoded["reason"] == message)
    }

    @Test
    func roundTripsThroughCodable() throws {
        let original = ClaudeHookOutput(reason: "test reason")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ClaudeHookOutput.self, from: data)
        #expect(decoded == original)
    }
}
