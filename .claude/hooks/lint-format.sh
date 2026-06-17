#!/usr/bin/env bash
# PostToolUse file edits: lint/format each file touched by the edit.
# Handles Claude (Write|Edit|MultiEdit → tool_input.file_path) and
# Codex (apply_patch → file markers in tool_input.command).
# Contract: exit 2 feeds the linter output back to the agent as correction feedback.
set -euo pipefail
# Portable project root: Claude sets CLAUDE_PROJECT_DIR; Codex does not, so fall back to git.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}"
HOOK_DIR="$PROJECT_DIR/.claude/hooks"
source "$HOOK_DIR/lib/json.sh"
source "$HOOK_DIR/lib/checks.sh"
payload="$(cat)"
status=0
while IFS= read -r file; do
  [ -z "$file" ] && continue
  if ! out="$(run_lint_for_file "$file" 2>&1)"; then
    printf '%s\n' "$out" >&2
    status=2
  fi
done < <(printf '%s' "$payload" | hook_changed_files)
exit "$status"
