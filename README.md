# docsync

[![Language](https://img.shields.io/badge/Language-Swift-F05138?style=flat-square)](https://www.swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey?style=flat-square)](https://github.com/Ryu0118/docsync/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-007ec6?style=flat-square)](LICENSE)

> Keep your documentation in sync with source code — automatically.

`docsync` computes a SHA-256 checksum of your source files and stores it alongside each doc rule in `docsync.yml`. When sources change, the stored checksum goes stale, and `docsync check` exits non-zero — making it trivial to enforce doc freshness in CI.

---

## Features

- **Checksum-based drift detection** — deterministic SHA-256 over sorted source file contents
- **YAML config** — human-readable, diff-friendly `docsync.yml`
- **Custom error messages** — per-rule `message` field to guide contributors on what to update
- **Two commands** — `check` (read-only, CI-safe) and `update` (rewrites checksums)
- **Cross-platform** — macOS and Linux (x86_64 / arm64)
- **No runtime dependencies** — single static binary on Linux

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Ryu0118/docsync/main/install.sh | bash
```

### Other methods

#### Nest ([mtj0928/nest](https://github.com/mtj0928/nest))

```bash
nest install Ryu0118/docsync
```

#### Mise ([jdx/mise](https://github.com/jdx/mise))

```bash
mise use -g ubi:Ryu0118/docsync
```

#### Build from source

Requires Swift 6.2+:

```bash
git clone https://github.com/Ryu0118/docsync
cd docsync
swift build -c release
cp .build/release/docsync /usr/local/bin/
```

---

## Quick start

### 1. Create `docsync.yml` in your project root

```yaml
rules:
  - name: api-doc
    sources:
      - src/api/user.ts
      - src/api/order.ts
    doc: docs/api.md

  - name: readme
    sources:
      - src/main.ts
    doc: README.md
```

### 2. Store the initial checksums

Before running `docsync check` for the first time, initialize the checksums:

```bash
docsync update
```

`docsync.yml` is rewritten with computed `checksum` fields:

```yaml
rules:
  - name: api-doc
    sources:
      - src/api/user.ts
      - src/api/order.ts
    doc: docs/api.md
    checksum: "a3f2e1..."
```

> **Note:** If you run `docsync check` before `docsync update`, you will see:
> ```
> [docsync] ⚠️  no checksum stored: api-doc — run `docsync update` first to initialize the checksum.
> ```
> This is expected on first setup. Run `docsync update` once to initialize, then commit the updated `docsync.yml`.

### 3. Check for drift

```bash
docsync check
```

Output when everything is in sync:

```
[docsync] ✅ all docs are in sync
```

Output when a source changed but the doc was not updated:

```
[docsync] ❌ out of sync: api-doc
  - sources changed but docs/api.md not updated
  After updating the docs, run `docsync update` to refresh the checksum.
```

Exit code `1` when out of sync, `0` when all rules pass.

### 4. Update checksums after editing docs

Once you have updated the documentation, refresh the stored checksum:

```bash
docsync update
```

Then commit both the updated doc and the updated `docsync.yml` together.

---

## Custom error messages

Use the `message` field to give contributors precise instructions on what to update:

```yaml
rules:
  - name: api-doc
    sources:
      - src/api/user.ts
      - src/api/order.ts
    doc: docs/api.md
    message: "The public API changed — update docs/api.md to reflect the new endpoints."
    checksum: "a3f2e1..."
```

When out of sync, `docsync check` outputs:

```
[docsync] ❌ out of sync: api-doc
  - The public API changed — update docs/api.md to reflect the new endpoints.
  After updating the docs, run `docsync update` to refresh the checksum.
```

The same message appears in the `--claude-hook` JSON payload, so AI agents receive the same guidance.

---

## CI integration

### GitHub Actions

```yaml
- name: Check doc sync
  run: docsync check
```

A complete workflow example lives in [`.github/workflows/test.yml`](.github/workflows/test.yml).

### Pre-commit hook

```sh
#!/bin/sh
docsync check || { echo "Docs are out of sync. Update the docs then run 'docsync update'."; exit 1; }
```

---

## Command reference

```
USAGE: docsync <subcommand>

SUBCOMMANDS:
  check    Verify that docs are in sync with source files.
  update   Recompute checksums and update docsync.yml.

OPTIONS:
  -c, --config <path>   Path to docsync.yml (default: docsync.yml)
  -h, --help            Show help information.
```

### `check` flags

| Flag | Description |
|------|-------------|
| `--claude-hook` | Emit Claude Code PostToolUse hook JSON to stdout and always exit 0. |

---

## Checksum algorithm

```
sorted(sources) → concatenate file bytes → SHA-256 → lowercase hex
```

Source paths are sorted alphabetically before hashing, so the result is independent of the order they appear in `docsync.yml`.

---

## Dev setup

```bash
make setup    # Install SwiftFormat, SwiftLint, my-swift-linter, gitnagg, periphery + configure git hooks
make check    # format + lint + ast-lint + test
swift test    # Run tests directly (no tooling required)
```

---

## License

MIT
