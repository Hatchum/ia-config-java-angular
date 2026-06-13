#!/usr/bin/env bash
# PostToolUse(Write|Edit|MultiEdit): lint/format the file that was just written.
# Contract: exit 2 feeds the linter output back to Claude as correction feedback.
set -euo pipefail
HOOK_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks"
source "$HOOK_DIR/lib/json.sh"
source "$HOOK_DIR/lib/checks.sh"
FILE="$(json_field '.tool_input.file_path')"
[ -z "${FILE:-}" ] && exit 0
if out="$(run_lint_for_file "$FILE" 2>&1)"; then
  exit 0
else
  printf '%s\n' "$out" >&2
  exit 2
fi
