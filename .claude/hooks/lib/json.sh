#!/usr/bin/env bash
# json.sh — extract one field from the hook event JSON (read from stdin).
# Usage: printf '%s' "$payload" | json_field '.tool_input.file_path'
# Prefers jq; falls back to a best-effort grep when jq is absent.
json_field() {
  local path="$1" payload key
  payload="$(cat)"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$payload" | jq -r "$path // empty"
  else
    key="${path##*.}"
    printf '%s' "$payload" \
      | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
      | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'
  fi
}
