import Foundation

struct Fixture {
    let directory: URL
    let configURL: URL
}

enum FixtureBuilder {
    static func build(rules: Int, sourcesPerRule: Int, fileSizeKB: Int) throws -> Fixture {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appending(path: "docsync-bench-\(UUID().uuidString)")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)

        let payload = String(repeating: "x", count: fileSizeKB * 1024)

        var yaml = "rules:\n"
        for ruleIndex in 0 ..< rules {
            let ruleName = "rule-\(ruleIndex)"
            let docPath = "docs/\(ruleName).md"
            yaml += "  - name: \(ruleName)\n"
            yaml += "    sources:\n"
            for sourceIndex in 0 ..< sourcesPerRule {
                let relativePath = "src/\(ruleName)/file-\(sourceIndex).txt"
                let fileURL = root.appending(path: relativePath)
                try fm.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try payload.write(to: fileURL, atomically: true, encoding: .utf8)
                yaml += "      - \(relativePath)\n"
            }
            yaml += "    doc: \(docPath)\n"
        }

        let configURL = root.appending(path: "docsync.yml")
        try yaml.write(to: configURL, atomically: true, encoding: .utf8)

        return Fixture(directory: root, configURL: configURL)
    }

    static func cleanup(_ fixture: Fixture) {
        try? FileManager.default.removeItem(at: fixture.directory)
    }
}
