#!/bin/sh
# Claude Code PreToolUse hook: architecture constraints
FILE_PATH=$(jq -r '.tool_input.file_path // ""')
NEW_CONTENT=$(jq -r '.tool_input.new_string // .tool_input.content // ""')

echo "$FILE_PATH" | grep -q '\.swift$' || exit 0

if echo "$NEW_CONTENT" | grep -q 'swiftlint:disable'; then
  echo '{"decision":"block","reason":"swiftlint:disable is not allowed. Fix the code instead."}'
  exit 2
fi

exit 0
