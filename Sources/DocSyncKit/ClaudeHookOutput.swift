import Foundation

/// The JSON payload emitted to a Claude Code or Codex PostToolUse hook.
package struct ClaudeHookOutput: Codable, Equatable {
    /// Always `"block"` — instructs the agent to stop and read the reason.
    package let decision: String
    /// Human-readable explanation of what is out of sync and what to do.
    package let reason: String

    /// Creates a blocking hook output with the given reason.
    package init(reason: String) {
        decision = "block"
        self.reason = reason
    }

    /// The payload encoded as a compact JSON string.
    package var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(self) else { return "{}" }
        return String(bytes: data, encoding: .utf8) ?? "{}"
    }
}
