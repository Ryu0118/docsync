---
name: docsync
description: "docsync is a CLI tool that keeps documentation in sync with source code via SHA-256 checksums. Use this skill when: (1) setting up docsync.yml for a new project, (2) a docsync check error appears (out of sync / missing checksum / glob no matches), (3) deciding what sources to tie to what docs, (4) adding glob patterns to docsync.yml, (5) integrating docsync into CI or git hooks."
---

# docsync

`docsync` ties source files to a doc file via a checksum. When sources change, `docsync check` exits non-zero and tells the agent exactly what to do.

## Core concept

```
sources (one or more files/globs) ──hash──► checksum ──stored in── docsync.yml
                                                                        │
                                                          docsync check compares
                                                          live hash vs stored hash
```

A rule is **in sync** when the live hash of the resolved sources matches the stored checksum.
A rule is **out of sync** when sources changed since `update-checksum` was last run.

---

## docsync.yml syntax

```yaml
excludes:                             # optional: glob patterns dropped from every rule
  - .build/**
  - node_modules/**
rules:
  - name: <unique-rule-id>          # required: identifies this rule in output
    sources:                        # required: files whose changes trigger a check
      - path/to/file.swift          # literal path
      - Sources/Rules/*Rule.swift   # * = one dir level
      - Sources/**/*.swift          # ** = recursive
      - Package.swift
    doc: README.md                  # required: the doc file tied to these sources
    message: "..."                  # optional: custom guidance shown to the agent
    checksum: "<sha256-hex>"        # managed by docsync update-checksum — do not edit manually
```

### Glob patterns

| Pattern | Behaviour |
|---------|-----------|
| `*` | Any characters within **one** directory level (`Sources/Rules/*Rule.swift`) |
| `**` | Zero or more directory levels (`Sources/**/*.swift`) |
| `?` | Any **single** character (not `/`) |

- A glob matching **zero files** is an error — the rule never passes.
- Adding a new file that matches an existing glob is detected automatically; no `docsync.yml` edit needed.
- Literal paths and globs can be mixed in the same `sources` list.

### Excludes

Top-level `excludes:` accepts the same glob syntax and is **strict** — patterns
match the full relative path, just like `sources`. To drop `.build` directories
nested anywhere under the project, write `**/.build/**`; `.build/**` only matches
a `.build/` at the project root.

- Excludes are applied **before** any rule's `sources` glob is expanded — useful
  for trimming `.build`, `node_modules`, generated bundles, etc.
- **Literal (non-glob) entries in `sources` bypass excludes.** If you list
  `.build/Generated.swift` explicitly it stays tracked even when `.build/**` is
  excluded; explicit user intent wins.
- A rule whose only matches were excluded raises the same `noGlobMatches` error
  so silent empty checksums never happen.

### Checksum algorithm

`expand_globs → sort paths → for each path: SHA-256(path + NUL + file_bytes) → hex`

Path is included in the hash, so renaming or adding a file changes the checksum even with identical content.

---

## Commands

```bash
docsync check                   # exits 1 if any rule is out of sync
docsync check --claude-hook     # outputs JSON to stdout, always exits 0 (for PostToolUse hooks)
docsync check --codex-hook      # same, Codex format
docsync update-checksum         # recompute all checksums and write to docsync.yml
docsync check -c path/to/docsync.yml   # custom config path
```

---

## Error states and agent actions

### ❌ out of sync

```
[docsync] ❌ out of sync: readme-cli
  - CLI command surface changed — update README (Usage section) if commands changed.
  Update the doc if needed, then run `docsync update-checksum` to resync the checksum.
```

**What happened:** Sources tracked by `readme-cli` changed since `update-checksum` was last run.

**Agent action:**
1. Read the `message` field — it says exactly which aspect of the doc to review.
2. `git diff` the listed sources to understand what changed.
3. Decide: does the doc need updating?
   - **Yes** → update the doc, then `docsync update-checksum`
   - **No** (change is internal, doc is still accurate) → `docsync update-checksum` only
4. Stage and commit `docsync.yml` together with any doc changes.

### ⚠️ no checksum stored (missing checksum)

```
[docsync] ⚠️  no checksum stored: api-doc (run `docsync update-checksum` first)
```

**What happened:** Rule exists in `docsync.yml` but `checksum` field is empty or absent — `update-checksum` was never run.

**Agent action:** Run `docsync update-checksum`, then commit `docsync.yml`.

### 💥 glob matched no files

```
Error: Glob pattern matched no files: Sources/Nonexistent/*.swift
```

**What happened:** A glob in `sources` resolved to zero files.

**Agent action:**
1. Check that the path prefix is correct relative to `docsync.yml`.
2. Fix the pattern in `docsync.yml`.
3. Re-run `docsync update-checksum`.

### 💥 source file not found (literal path)

```
Error: Source file not found: src/api/user.ts
```

**What happened:** A literal path in `sources` doesn't exist.

**Agent action:** Fix the path or remove the entry from `docsync.yml`.

---

## How to design rules (best practices)

### Rule granularity

One rule per "concern". Don't lump unrelated sources into one rule — the message becomes useless.

```yaml
# ✅ good: each rule has a clear, focused message
rules:
  - name: readme-cli
    sources: [Sources/CLI/Command.swift]
    doc: README.md
    message: "CLI flags changed — update README Usage section."

  - name: readme-config
    sources: [Sources/Kit/Config.swift]
    doc: README.md
    message: "Config schema changed — update README config format section."

# ❌ bad: everything in one rule, message is vague
rules:
  - name: readme
    sources: [Sources/**/*.swift]
    doc: README.md
    message: "Something changed."
```

### Write precise messages

The `message` field is the primary signal to the agent. Make it answer:
- **What changed?** (which concern/surface)
- **What to review in the doc?** (which section)
- **Under what condition must the doc be updated?** (if needed)

```yaml
message: "Public API surface changed — review README (API reference section) and update
  only if the method signatures, parameters, or return types changed."
```

### Use globs for extensible lists

When a directory will grow over time (rules, commands, handlers), use a glob so new files are tracked automatically:

```yaml
sources:
  - Sources/Rules/*Rule.swift    # new XxxRule.swift files auto-detected
```

### Tie sources to the right doc

| Source type | Tie to |
|-------------|--------|
| CLI commands / flags | README.md (Usage section) |
| Config schema / models | README.md (Config section) or CLAUDE.md |
| Core architecture / patterns | CLAUDE.md |
| MCP tools / handlers | README.md (Tools table) |
| Public API surface | README.md (API reference) |

### Self-hosting docsync itself

Add a rule that tracks the sources that affect user-visible behavior — and ties them to the README:

```yaml
- name: readme
  sources:
    - Sources/CLI/CheckCommand.swift
    - Sources/Kit/ClaudeHookOutput.swift
  doc: README.md
  message: "CLI surface or hook payload changed — update README only if user-facing behavior changed."
```

---

## Setup workflow for a new project

```bash
# 1. Install docsync
nest install Ryu0118/docsync        # or: curl -fsSL .../install.sh | bash

# 2. Create docsync.yml (no checksum fields yet)
# 3. Initialize checksums
docsync update-checksum

# 4. Commit
git add docsync.yml
git commit -m "Add docsync for doc/source sync"
```

---

## Hook output format (--claude-hook)

```json
{"decision":"block","reason":"out of sync: readme-cli — CLI command surface changed...\nUpdate the doc if needed, then run `docsync update-checksum` to resync the checksum."}
```

`decision: "block"` stops the agent's current action. The agent reads `reason` and follows the embedded instructions before proceeding.
