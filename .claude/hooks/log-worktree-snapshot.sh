#!/usr/bin/env bash
# Stop/SubagentStop: scan the working tree once per turn so file changes made
# via raw Bash (sed, scripts, mv...) are captured too, not just the Write/Edit/
# MultiEdit calls matched by log-changes.sh's PostToolUse hook. Per
# code.claude.com/docs/en/hooks: "If your hook must see every file change, such
# as for compliance scanning or audit logging, add a Stop hook that scans the
# working tree once per turn." Appends to the SAME log as log-changes.sh
# (event worktree_snapshot vs tool_edit) so both views live in one file.
# Never blocks (always exit 0).
set -euo pipefail
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}"
HOOK_DIR="$PROJECT_DIR/.claude/hooks"
source "$HOOK_DIR/lib/json.sh"
LOG="$PROJECT_DIR/.claude/logs/agent-activity.jsonl"
payload="$(cat)"
agent_type="$(printf '%s' "$payload" | json_field '.agent_type')"
agent_id="$(printf '%s' "$payload" | json_field '.agent_id')"
session_id="$(printf '%s' "$payload" | json_field '.session_id')"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  status="${line:0:2}"
  path="${line:3}"
  jsonl_append "$LOG" \
    timestamp "$ts" event worktree_snapshot session_id "${session_id:-}" \
    agent_type "${agent_type:-main}" agent_id "${agent_id:--}" status "$status" file "$path"
done < <(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || true)
exit 0
