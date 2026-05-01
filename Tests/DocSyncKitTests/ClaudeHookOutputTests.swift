// swiftformat:disable redundantSwiftTestingSuite
@testable import DocSyncKit
import Foundation
import Testing

@Suite
struct ClaudeHookOutputTests {
    @Test
    func `decision is always block`() {
        let output = ClaudeHookOutput(reason: "anything")
        #expect(output.decision == "block")
    }

    @Test
    func `jsonString returns block decision with reason`() {
        let output = ClaudeHookOutput(reason: "Docs out of sync.")
        #expect(output.jsonString == "{\"decision\":\"block\",\"reason\":\"Docs out of sync.\"}")
    }

    @Test
    func `jsonString escapes double quotes in reason`() throws {
        let message = #"Stop: "update" docs"#
        let output = ClaudeHookOutput(reason: message)
        let data = Data(output.jsonString.utf8)
        let decoded = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(decoded["decision"] == "block")
        #expect(decoded["reason"] == message)
    }

    @Test
    func `jsonString escapes backslashes in reason`() throws {
        let message = #"path\to\file"#
        let output = ClaudeHookOutput(reason: message)
        let data = Data(output.jsonString.utf8)
        let decoded = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(decoded["reason"] == message)
    }

    @Test
    func `jsonString escapes newlines in reason`() throws {
        let message = "line1\nline2"
        let output = ClaudeHookOutput(reason: message)
        let data = Data(output.jsonString.utf8)
        let decoded = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(decoded["reason"] == message)
    }

    @Test
    func `round trips through Codable`() throws {
        let original = ClaudeHookOutput(reason: "test reason")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ClaudeHookOutput.self, from: data)
        #expect(decoded == original)
    }
}
