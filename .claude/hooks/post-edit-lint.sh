#!/bin/sh
INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""')
printf '%s' "$FILE_PATH" | grep -q '\.swift$' || exit 0
[ -f "$FILE_PATH" ] || exit 0

SRCROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

ALL_REASONS=""

# Resolve relative path
if [ ! -f "$FILE_PATH" ] && [ -f "$SRCROOT/$FILE_PATH" ]; then
  FILE_PATH="$SRCROOT/$FILE_PATH"
fi

# 1. swiftformat
if [ -x "$SRCROOT/.nest/bin/swiftformat" ]; then
  SWIFTFORMAT="$SRCROOT/.nest/bin/swiftformat"
elif command -v swiftformat >/dev/null 2>&1; then
  SWIFTFORMAT=$(command -v swiftformat)
else
  SWIFTFORMAT=""
fi
if [ -n "$SWIFTFORMAT" ] && [ -f "$SRCROOT/.swiftformat" ]; then
  "$SWIFTFORMAT" --config "$SRCROOT/.swiftformat" "$FILE_PATH" 2>/dev/null || true
fi

# 2. swiftlint
if [ -x "$SRCROOT/.nest/bin/swiftlint" ]; then
  SWIFTLINT="$SRCROOT/.nest/bin/swiftlint"
elif command -v swiftlint >/dev/null 2>&1; then
  SWIFTLINT=$(command -v swiftlint)
else
  SWIFTLINT=""
fi
if [ -n "$SWIFTLINT" ] && [ -f "$SRCROOT/.swiftlint.yml" ]; then
  LINT_OUTPUT=$("$SWIFTLINT" lint --config "$SRCROOT/.swiftlint.yml" --strict --quiet "$FILE_PATH" 2>&1) || true
  if [ -n "$LINT_OUTPUT" ]; then
    ALL_REASONS="${ALL_REASONS}${LINT_OUTPUT}\n"
  fi
fi

# 3. gitnagg — capture plain (non-timestamp) output only; exit code is irrelevant
if [ -x "$SRCROOT/.nest/bin/gitnagg" ] && [ -f "$SRCROOT/.gitnagg.yml" ]; then
  NAGG_OUTPUT=$("$SRCROOT/.nest/bin/gitnagg" check --config "$SRCROOT/.gitnagg.yml" 2>&1 \
    | grep -v '^[0-9][0-9][0-9][0-9]-' || true)
  if [ -n "$NAGG_OUTPUT" ]; then
    ALL_REASONS="${ALL_REASONS}${NAGG_OUTPUT}\n"
  fi
fi

# Report to Claude via JSON stdout (exit 0 is required — JSON is ignored on any other exit code)
if [ -n "$ALL_REASONS" ]; then
  REASON=$(printf '%b' "$ALL_REASONS" | jq -Rs .)
  printf '{"decision":"block","reason":%s}\n' "$REASON"
fi

exit 0
