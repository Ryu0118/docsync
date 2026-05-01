# docsync

[![Language](https://img.shields.io/badge/Language-Swift-F05138?style=flat-square)](https://www.swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey?style=flat-square)](https://github.com/Ryu0118/docsync/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-007ec6?style=flat-square)](LICENSE)

**Stop letting docs rot. Keep them honest with every code change.**

`docsync` ties documentation to source files via SHA-256 checksums. When the sources drift, `docsync check` exits non-zero — so your CI catches stale docs before they reach reviewers. Built for agentic coding workflows where AI agents need reliable, up-to-date context.

## Features

- 📎 **Tie docs to source** — declare which files must stay in sync with which doc
- 🚨 **Catch drift in CI** — `docsync check` exits non-zero the moment sources change without a doc update
- 🤖 **Agent-aware** — `--claude-hook` / `--codex-hook` feeds structured guidance back to agents so they self-correct instantly

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
```

### 2. Initialize checksums

```bash
docsync update
```

Skip this step if you're adding docsync to an existing project where the docs are already up to date — just run `docsync update` once to stamp the initial checksums, then commit `docsync.yml`.

### 3. Check for drift

```bash
docsync check
```

```
[docsync] ❌ out of sync: api-doc
  - sources changed but docs/api.md not updated
  After updating the docs, run `docsync update` to refresh the checksum.
```

### 4. Update checksums after editing docs

```bash
docsync update
```

---

## Custom error messages

```yaml
rules:
  - name: api-doc
    sources:
      - src/api/user.ts
    doc: docs/api.md
    message: "The public API changed — update docs/api.md to reflect the new endpoints."
    checksum: "a3f2e1..."
```

---

## Agentic coding integration

### Claude Code hook

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "docsync check --claude-hook"
          }
        ]
      }
    ]
  }
}
```

### Codex hook

```json
{
  "hooks": {
    "post-tool-use": [
      {
        "command": "docsync check --codex-hook"
      }
    ]
  }
}
```

---

## CI integration

```yaml
- name: Check doc sync
  run: docsync check
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
| `--codex-hook` | Emit Codex PostToolUse hook JSON to stdout and always exit 0. |

---

## License

MIT
