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

## Tooling

| Tool | Version | 用途 |
|------|---------|------|
| SwiftFormat | 0.60.1 | コードフォーマット |
| SwiftLint | 0.63.2 | Lint (strict) |
| gitnagg | 0.2.1 | コミットサイズ警告 |
| periphery | 3.6.0 | 未使用コード検出 |

nest でローカル `.nest/bin/` にインストール。`make setup` で一発セットアップ。

## Dev setup

```bash
make setup        # nest install (SwiftFormat/SwiftLint/gitnagg/periphery) + git hooks 設定
make check        # format → lint → test を順に実行
swift test        # テストのみ直接実行
make format       # SwiftFormat のみ
make lint         # SwiftLint --strict のみ
```

**必須**: `make setup` を先に実行しないと `make format`/`make lint` は失敗する。
`swift test` はツールなしで実行可能。

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
