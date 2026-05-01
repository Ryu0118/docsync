# docsync

CLI tool that keeps documentation in sync with source code via SHA-256 checksums.

## Project structure

```
Sources/
  docsync/        # Executable: @main only, delegates to DocSyncCommand.main()
  DocSyncCLI/     # CLI layer: subcommand structs that call XxxRunner.run()
  DocSyncKit/     # All business logic: models, checksum, runners, config
Tests/
  DocSyncKitTests/  # swift-testing, targeting 90%+ coverage
```

## Architecture rules

- The `docsync` executable must contain **no business logic** — only `DocSyncCommand.main()`
- All logic lives in `DocSyncKit`
- `DocSyncCLI` subcommands call `XxxRunner(…).run()` — no logic beyond argument parsing and output
- No `swiftlint:disable` without explicit approval
- No `URL(fileURLWithPath:)` — use `URL(filePath:)` instead
- No `nonisolated(unsafe)`
- Use `FileManagerProtocol` for all file I/O to keep tests mockable
- Checksums are deterministic pure functions: sort sources alphabetically before hashing

## Tooling

| Tool | Version | Purpose |
|------|---------|---------|
| SwiftFormat | 0.60.1 | Code formatting |
| SwiftLint | 0.63.2 | Linting (strict) |
| my-swift-linter | 0.3.0 | AST-level lint rules |
| gitnagg | 0.2.1 | Commit size warnings |
| periphery | 3.6.0 | Unused code detection |

All tools are installed locally into `.nest/bin/` via `nest`. Run `make setup` first.

## Dev setup

```bash
make setup        # Install all tools via nest + configure git hooks
make check        # format → lint → ast-lint → test
make format       # SwiftFormat only
make lint         # SwiftLint --strict only
make ast-lint     # my-swift-linter AST checks only
swift test        # Run tests directly (no tooling required)
```

**Required:** Run `make setup` before `make format`, `make lint`, or `make ast-lint`.
`swift test` works without setup.

## Config format (docsync.yml)

```yaml
rules:
  - name: api-doc
    sources:
      - src/api/user.ts
    doc: docs/api.md
    checksum: "<sha256-hex>"
```

## Checksum algorithm

`sorted(sources) → concatenate file bytes → SHA-256 → lowercase hex`
