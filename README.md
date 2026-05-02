# docsync

[![Language](https://img.shields.io/badge/Language-Swift-F05138?style=flat-square)](https://www.swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey?style=flat-square)](https://github.com/Ryu0118/docsync/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-007ec6?style=flat-square)](LICENSE)

**Keep docs fresh for agentic coding workflows.**

`docsync` ties documentation to source files. When sources change without a matching doc update, `docsync check` exits non-zero — so stale docs never mislead your AI agent.

## Features

- 📎 **Tie docs to source** — declare which files must stay in sync with which doc
- 🚨 **Detects stale docs automatically** — fails when source changes but the doc isn't updated
- 🤖 **Agent-aware** — `--claude-hook` / `--codex-hook` feeds structured guidance back to agents so they self-correct instantly

## Install

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

## Agent Skills

Install the **docsync** skill so your AI agent understands the config syntax, error messages, and best practices — and knows exactly what action to take when `docsync check` fails.

```bash
# ~/.agents/skills/ (Agent Skills standard)
mkdir -p ~/.agents/skills/docsync
curl -fsSL https://raw.githubusercontent.com/Ryu0118/docsync/main/.agents/skills/docsync/SKILL.md \
  -o ~/.agents/skills/docsync/SKILL.md

# Claude Code: also install to ~/.claude/skills/
mkdir -p ~/.claude/skills/docsync
curl -fsSL https://raw.githubusercontent.com/Ryu0118/docsync/main/.agents/skills/docsync/SKILL.md \
  -o ~/.claude/skills/docsync/SKILL.md
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
docsync update-checksum
```

Skip this step if you're adding docsync to an existing project where the docs are already up to date — just run `docsync update-checksum` once to stamp the initial checksums, then commit `docsync.yml`.

### 3. Check for drift

```bash
docsync check
```

```
[docsync] ❌ out of sync: api-doc
  - sources changed since last checksum: docs/api.md
  Update the doc if needed, then run `docsync update-checksum` to resync the checksum.
```

### 4. Resync the checksum

Whether you updated the doc or intentionally left it unchanged, stamp the new checksum:

```bash
docsync update-checksum
```

---

## Glob patterns

`sources` accepts glob patterns in addition to literal paths:

| Pattern | Matches |
|---------|---------|
| `*` | Any sequence of characters within one directory level |
| `**` | Zero or more directory levels (recursive) |
| `?` | Any single character (not `/`) |

```yaml
rules:
  - name: rules-doc
    sources:
      - Sources/Rules/*Rule.swift   # all *Rule.swift in one directory
      - Sources/**/*.swift          # all .swift files recursively
      - Package.swift               # literal path
    doc: README.md
```

A glob that matches zero files is an error. Adding a new file that matches an existing glob is detected automatically — no need to update `docsync.yml`.

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
  check             Verify that docs are in sync with source files.
  update-checksum   Recompute checksums and update docsync.yml.

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
