#!/usr/bin/env bash
# SubagentStart/SubagentStop: append a human-traceable JSON Lines record of when
# each subagent started/finished, to .claude/logs/agent-runs.jsonl (local,
# gitignored). Keyed by the subagent's static name (agent_type) and its
# per-invocation agent_id — fields confirmed present on these two events
# (code.claude.com/docs/en/hooks). Lets a human reconstruct "who ran, when"
# without parsing the raw per-subagent transcript JSONL files.
# Never blocks (always exit 0).
set -euo pipefail
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}"
HOOK_DIR="$PROJECT_DIR/.claude/hooks"
source "$HOOK_DIR/lib/json.sh"
LOG="$PROJECT_DIR/.claude/logs/agent-runs.jsonl"
payload="$(cat)"
hook_event="$(printf '%s' "$payload" | json_field '.hook_event_name')"
agent_type="$(printf '%s' "$payload" | json_field '.agent_type')"
agent_id="$(printf '%s' "$payload" | json_field '.agent_id')"
session_id="$(printf '%s' "$payload" | json_field '.session_id')"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
case "$hook_event" in
  SubagentStart) event="subagent_start" ;;
  SubagentStop)  event="subagent_stop" ;;
  *)             event="${hook_event:-unknown}" ;;
esac
jsonl_append "$LOG" \
  timestamp "$ts" event "$event" session_id "${session_id:-}" \
  agent_type "${agent_type:-?}" agent_id "${agent_id:--}"
exit 0
