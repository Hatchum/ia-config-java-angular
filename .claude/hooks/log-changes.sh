#!/usr/bin/env bash
# PostToolUse file edits: append each touched file to a local, gitignored changelog.
# Handles Claude (tool_input.file_path) and Codex (apply_patch tool_input.command).
# Never blocks (always exit 0).
set -euo pipefail
# Portable project root: Claude sets CLAUDE_PROJECT_DIR; Codex does not, so fall back to git.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}"
HOOK_DIR="$PROJECT_DIR/.claude/hooks"
source "$HOOK_DIR/lib/json.sh"
LOG="$PROJECT_DIR/.claude/changes.local.log"
payload="$(cat)"
tool="$(printf '%s' "$payload" | json_field '.tool_name')"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
while IFS= read -r file; do
  [ -z "$file" ] && continue
  printf '%s\t%s\t%s\n' "$ts" "${tool:-?}" "$file" >> "$LOG"
done < <(printf '%s' "$payload" | hook_changed_files)
exit 0
