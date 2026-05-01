#!/bin/sh
# PostToolUse hook: run docsync check with binary caching.
#
# Cache key = SHA-256 of (docsync.yml + all source files listed in docsync.yml + Package.resolved).
# If the key is unchanged from last run, skip execution entirely.
# Binary resolution: .build/release/docsync → .build/debug/docsync → PATH docsync → swift run docsync (slow).

SRCROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
CONFIG="$SRCROOT/docsync.yml"
[ -f "$CONFIG" ] || exit 0

CACHE_DIR="$SRCROOT/.docsync-cache"
mkdir -p "$CACHE_DIR"
CACHE_KEY_FILE="$CACHE_DIR/last-key"

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

# --- Compute cache key ---
RESOLVED="$SRCROOT/Package.resolved"
KEY_INPUT="$CONFIG"
[ -f "$RESOLVED" ] && KEY_INPUT="$KEY_INPUT $RESOLVED"
CACHE_KEY=$(cat $KEY_INPUT 2>/dev/null | shasum -a 256 | awk '{print $1}')

# --- Skip if unchanged ---
if [ -f "$CACHE_KEY_FILE" ] && [ "$(cat "$CACHE_KEY_FILE")" = "$CACHE_KEY" ]; then
  exit 0
fi

# --- Run check ---
OUTPUT=$(eval "$DOCSYNC check --claude-hook --config '$CONFIG'" 2>/dev/null)
EXIT=$?

# Update cache key only on success (non-error exit)
if [ $EXIT -eq 0 ]; then
  echo "$CACHE_KEY" > "$CACHE_KEY_FILE"
fi

[ -n "$OUTPUT" ] && printf '%s\n' "$OUTPUT"
exit 0
