import Foundation

struct Fixture {
    let directory: URL
    let configURL: URL
}

enum FixtureBuilder {
    static func build(
        rules: Int,
        sourcesPerRule: Int,
        fileSizeKB: Int,
        extraFiles: Int = 0,
        useGlobPatterns: Bool = false,
    ) throws -> Fixture {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appending(path: "docsync-bench-\(UUID().uuidString)")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)

        let payload = String(repeating: "x", count: fileSizeKB * 1024)

        try writeRuleSourceFiles(
            root: root,
            rules: rules,
            sourcesPerRule: sourcesPerRule,
            payload: payload,
            fileManager: fm,
        )
        try writeExtraNoiseFiles(
            root: root,
            count: extraFiles,
            payload: payload,
            fileManager: fm,
        )

        let yaml = renderYAML(
            rules: rules,
            sourcesPerRule: sourcesPerRule,
            useGlobPatterns: useGlobPatterns,
        )
        let configURL = root.appending(path: "docsync.yml")
        try yaml.write(to: configURL, atomically: true, encoding: .utf8)

        return Fixture(directory: root, configURL: configURL)
    }

    static func cleanup(_ fixture: Fixture) {
        try? FileManager.default.removeItem(at: fixture.directory)
    }

    // MARK: - Helpers

    private static func writeRuleSourceFiles(
        root: URL,
        rules: Int,
        sourcesPerRule: Int,
        payload: String,
        fileManager: FileManager,
    ) throws {
        try (0 ..< rules).forEach { ruleIndex in
            try (0 ..< sourcesPerRule).forEach { sourceIndex in
                let url = root.appending(path: "src/rule-\(ruleIndex)/file-\(sourceIndex).txt")
                try fileManager.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true,
                )
                try payload.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private static func writeExtraNoiseFiles(
        root: URL,
        count: Int,
        payload: String,
        fileManager: FileManager,
    ) throws {
        guard count > 0 else { return }
        let noiseDir = root.appending(path: "noise")
        try fileManager.createDirectory(at: noiseDir, withIntermediateDirectories: true)
        // Spread files across 100 subdirectories to mimic real project structure.
        let bucketCount = max(1, min(100, count / 50))
        try (0 ..< count).forEach { index in
            let bucket = index % bucketCount
            let url = noiseDir.appending(path: "bucket-\(bucket)/noise-\(index).bin")
            try fileManager.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
            try payload.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private static func renderYAML(
        rules: Int,
        sourcesPerRule: Int,
        useGlobPatterns: Bool,
    ) -> String {
        let header = "rules:\n"
        let body = (0 ..< rules)
            .map { renderRule(index: $0, sourcesPerRule: sourcesPerRule, useGlobPatterns: useGlobPatterns) }
            .joined()
        return header + body
    }

    private static func renderRule(
        index: Int,
        sourcesPerRule: Int,
        useGlobPatterns: Bool,
    ) -> String {
        let ruleName = "rule-\(index)"
        let sourcesYAML: String = if useGlobPatterns {
            "      - src/\(ruleName)/*.txt\n"
        } else {
            (0 ..< sourcesPerRule)
                .map { "      - src/\(ruleName)/file-\($0).txt\n" }
                .joined()
        }
        return """
          - name: \(ruleName)
            sources:
        \(sourcesYAML)    doc: docs/\(ruleName).md

        """
    }
}
