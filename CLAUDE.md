# docsync

CLI tool that keeps documentation in sync with source code via SHA-256 checksums.

## Project structure

```
Sources/
  docsync/        # Executable: @main only, calls DocSyncCommand.main()
  DocSyncCLI/     # CLI layer: subcommand structs calling Runner.run()
  DocSyncKit/     # All logic: models, checksum, runners, config
Tests/
  DocSyncKitTests/  # swift-testing, target 90%+ coverage
```

## Rules

- Executable (`docsync`) must contain NO business logic — only `DocSyncCommand.main()`
- All logic lives in `DocSyncKit`
- `DocSyncCLI` calls `XxxRunner(…).run()` — no logic beyond argument parsing and output
- No `swiftlint:disable` without explicit approval
- No `URL(fileURLWithPath:)` — use `URL(filePath:)` instead
- No `nonisolated(unsafe)`
- Use `FileManagerProtocol` for all file I/O so tests can mock it
- Checksums are pure functions: deterministic, sort sources first

## Dev setup

```bash
make setup    # installs SwiftFormat, SwiftLint, gitnagg, periphery via nest + configures git hooks
make check    # format + lint + test
swift test    # run tests directly
```

## Config format

```yaml
rules:
  - name: api-doc
    sources:
      - src/api/user.ts
    doc: docs/api.md
    checksum: "<sha256-hex>"
```

## Checksum algorithm

`sorted(sources) → concatenate file bytes → SHA256 → lowercase hex`
