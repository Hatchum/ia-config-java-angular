#!/usr/bin/env bash
# PostToolUse(Write|Edit|MultiEdit): append an entry to a local, gitignored changelog.
# Never blocks (always exit 0).
set -euo pipefail
HOOK_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks"
source "$HOOK_DIR/lib/json.sh"
LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/changes.local.log"
payload="$(cat)"
file="$(printf '%s' "$payload" | json_field '.tool_input.file_path')"
tool="$(printf '%s' "$payload" | json_field '.tool_name')"
[ -z "${file:-}" ] && exit 0
printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${tool:-?}" "$file" >> "$LOG"
exit 0
