import Foundation

package struct ClaudeHookOutput: Codable, Equatable {
    package let decision: String
    package let reason: String

    package init(reason: String) {
        decision = "block"
        self.reason = reason
    }

    package var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(self) else { return "{}" }
        return String(bytes: data, encoding: .utf8) ?? "{}"
    }
}
