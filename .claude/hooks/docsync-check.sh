#!/bin/sh
# PostToolUse hook: run docsync check after every edit.
#
# Binary resolution: .build/release/docsync → .build/debug/docsync → PATH docsync → build release binary.

SRCROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
CONFIG="$SRCROOT/docsync.yml"
[ -f "$CONFIG" ] || exit 0

# --- Resolve binary ---
if [ -x "$SRCROOT/.build/release/docsync" ]; then
  DOCSYNC="$SRCROOT/.build/release/docsync"
elif [ -x "$SRCROOT/.build/debug/docsync" ]; then
  DOCSYNC="$SRCROOT/.build/debug/docsync"
elif command -v docsync >/dev/null 2>&1; then
  DOCSYNC="docsync"
else
  echo "[docsync] No pre-built binary found — building now..." >&2
  swift build -c release --package-path "$SRCROOT" >&2 || exit 0
  DOCSYNC="$SRCROOT/.build/release/docsync"
fi

# --- Run check ---
OUTPUT=$(eval "$DOCSYNC check --claude-hook --config '$CONFIG'" 2>/dev/null)
[ -n "$OUTPUT" ] && printf '%s\n' "$OUTPUT"
exit 0
