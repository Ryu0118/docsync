#!/bin/sh
# PostToolUse hook: run docsync check after every edit.
#
# Binary resolution: .build/release/docsync → .build/debug/docsync → PATH docsync → swift run docsync (slow).

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
  DOCSYNC="swift run --package-path '$SRCROOT' docsync"
  echo "[docsync] No pre-built binary found — falling back to 'swift run' (slow). Run 'swift build -c release' to speed this up." >&2
fi

# --- Run check ---
OUTPUT=$(eval "$DOCSYNC check --claude-hook --config '$CONFIG'" 2>/dev/null)
[ -n "$OUTPUT" ] && printf '%s\n' "$OUTPUT"
exit 0
