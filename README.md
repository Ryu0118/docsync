# docsync

> Keep your documentation in sync with source code — automatically.

`docsync` computes a SHA-256 checksum of your source files and stores it alongside each doc rule in `docsync.yml`. When sources change, the stored checksum goes stale, and `docsync check` exits non-zero — making it trivial to enforce doc freshness in CI.

---

## Features

- **Checksum-based drift detection** — deterministic SHA-256 over sorted source file contents
- **YAML config** — human-readable, diff-friendly `docsync.yml`
- **Two commands** — `check` (read-only, CI-safe) and `update` (rewrites checksums)
- **Cross-platform** — macOS and Linux (x86_64 / arm64)
- **No runtime dependencies** — single static binary on Linux

---

## Installation

### Download binary

Grab the latest archive from [Releases](../../releases) and place the binary on your `$PATH`:

```bash
tar xf docsync-<version>-darwin-universal.tar.gz
mv docsync /usr/local/bin/
```

### Build from source

Requires Swift 6.2+:

```bash
git clone https://github.com/yourorg/docsync
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
```

Exit code `1` when out of sync, `0` when all rules pass.

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
docsync check || { echo "Run 'docsync update' and commit the updated docsync.yml"; exit 1; }
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
