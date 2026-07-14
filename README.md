# docsync

[![Language](https://img.shields.io/badge/Language-Swift-F05138?style=flat-square)](https://www.swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey?style=flat-square)](https://github.com/Ryu0118/docsync/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-007ec6?style=flat-square)](LICENSE)

**Keep docs in sync with source across CI, git hooks, and agentic workflows.**

`docsync` ties documentation to source files via checksums. When sources drift from their docs, `docsync check` exits non-zero, catching stale docs in CI pipelines, pre-commit hooks, and agentic coding workflows before they cause confusion.

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
mise use -g github:Ryu0118/docsync
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

These commands install the agent skill/plugin metadata, not the `docsync`
binary. Install the binary separately with `curl`, Nest, mise, or from source.

### Claude Code

```sh
/plugin marketplace add Ryu0118/docsync
/plugin install docsync@docsync
```

### Codex

Add the marketplace, then install the plugin:

```sh
codex plugin marketplace add Ryu0118/docsync
codex plugin add docsync@docsync
```

To develop against a local clone instead, point the marketplace at the checkout:

```sh
git clone https://github.com/Ryu0118/docsync
codex plugin marketplace add ./docsync
codex plugin add docsync@docsync
```

### APM (Agent Package Manager)

With [APM](https://github.com/microsoft/apm), one command installs the skill
into any supported harness (Claude Code, Copilot, Cursor, Codex, and more) and
pins it in `apm.lock.yaml`:

```sh
apm install Ryu0118/docsync
```

### GitHub CLI (`gh skill`)

[GitHub CLI v2.90.0+](https://github.blog/changelog/2026-04-16-manage-agent-skills-with-github-cli/)
ships a `gh skill` command (alias: `gh skills`). It pins to the latest release
tag and records provenance (repo, ref, tree SHA) in the installed SKILL.md:

```sh
gh skill install Ryu0118/docsync docsync --agent claude-code
```

Run `gh skill install Ryu0118/docsync` without a skill name for interactive
selection, and use `--agent` / `--scope` to control where skills land.

### skills CLI (`npx skills`)

The [skills CLI](https://github.com/vercel-labs/skills) installs into the
shared `.agents/skills/` directory used by many agents:

```sh
npx skills add Ryu0118/docsync --all
```

Use `--list` to inspect available skills first, or `-a claude-code` to target
a specific agent.

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

## Excludes

Trim noisy paths (build artefacts, vendored deps) from every rule with a top-level `excludes:` list. Excludes use the same glob syntax as `sources` and are matched **strictly** against the relative path — patterns are not anchored to nested directories the way `.gitignore` does. Write `**/.build/**` to drop `.build` directories at any depth.

```yaml
excludes:
  - .build/**
  - node_modules/**
  - "**/Generated/**"
rules:
  - name: sources
    sources:
      - Sources/**/*.swift
    doc: docs/architecture.md
```

- Excludes are applied **before** any rule's glob is expanded, so they speed up checks on large projects.
- **Literal entries in `sources` bypass excludes.** Listing `.build/Generated.swift` explicitly keeps it tracked even when `.build/**` is excluded.
- If every match for a rule is excluded the rule fails with the same "glob matched no files" error you get without excludes.

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
OVERVIEW: Keep documentation in sync with source code.

USAGE: docsync <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  check                   Verify that docs are in sync with source files.
  update-checksum         Recompute checksums and update docsync.yml.

  See 'docsync help <subcommand>' for detailed help.
```

```
OVERVIEW: Verify that docs are in sync with source files.

USAGE: docsync check [--config <config>] [--claude-hook] [--codex-hook]

OPTIONS:
  -c, --config <config>   Path to docsync.yml. (default: docsync.yml)
  --claude-hook           Emit Claude Code hook JSON to stdout and exit 0.
                          Mutually exclusive with --codex-hook.
  --codex-hook            Emit Codex hook JSON to stdout and exit 0. Mutually
                          exclusive with --claude-hook.
  -h, --help              Show help information.
```

```
OVERVIEW: Recompute checksums and update docsync.yml.

USAGE: docsync update-checksum [--config <config>]

OPTIONS:
  -c, --config <config>   Path to docsync.yml. (default: docsync.yml)
  -h, --help              Show help information.
```

---

## License

MIT
