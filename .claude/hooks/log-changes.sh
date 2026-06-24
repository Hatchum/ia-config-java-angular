#!/usr/bin/env bash
# PostToolUse file edits: append one JSON Lines audit record per touched file
# to .claude/logs/agent-activity.jsonl (local, gitignored).
# Handles Claude (tool_input.file_path) and Codex (apply_patch tool_input.command).
# agent_type/agent_id are present in the hook payload only when the call comes
# from inside a subagent (confirmed: code.claude.com/docs/en/hooks) — "main"/"-"
# otherwise, so every line is attributable to the agent that made the edit.
# JSONL audit pattern per code.claude.com/docs/en/hooks ("Audit configuration
# changes" example). Complemented by log-worktree-snapshot.sh (event
# worktree_snapshot in the same file) for changes made via raw Bash.
# Never blocks (always exit 0).
set -euo pipefail
# Portable project root: Claude sets CLAUDE_PROJECT_DIR; Codex does not, so fall back to git.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}"
HOOK_DIR="$PROJECT_DIR/.claude/hooks"
source "$HOOK_DIR/lib/json.sh"
LOG="$PROJECT_DIR/.claude/logs/agent-activity.jsonl"
payload="$(cat)"
tool="$(printf '%s' "$payload" | json_field '.tool_name')"
agent_type="$(printf '%s' "$payload" | json_field '.agent_type')"
agent_id="$(printf '%s' "$payload" | json_field '.agent_id')"
session_id="$(printf '%s' "$payload" | json_field '.session_id')"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
while IFS= read -r file; do
  [ -z "$file" ] && continue
  jsonl_append "$LOG" \
    timestamp "$ts" event tool_edit session_id "${session_id:-}" \
    agent_type "${agent_type:-main}" agent_id "${agent_id:--}" tool "${tool:-?}" file "$file"
done < <(printf '%s' "$payload" | hook_changed_files)
exit 0
