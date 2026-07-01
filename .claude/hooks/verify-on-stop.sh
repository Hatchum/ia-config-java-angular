#!/usr/bin/env bash
# Stop gate (task P4, docs/research/agentique.md): block ending a session on a
# dirty worktree whose verification command fails — the deterministic
# complement to the subagents' self-declared `STATUS: completed`, per
# code.claude.com/docs/en/hooks (a Stop hook exiting 2 blocks stoppage and
# feeds stderr back to Claude for correction).
# Ships INERT: a VERIFY_CMD still containing "<" (lib/checks.sh) is treated as
# UNCONFIGURED and skipped (exit 0) — same convention as the lint commands.
# Loop protection: exits 0 when stop_hook_active is true (payload field set by
# Claude Code on a stop retriggered by a blocked stop), so a red build cannot
# trap the session forever.
set -euo pipefail
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}"
HOOK_DIR="$PROJECT_DIR/.claude/hooks"
source "$HOOK_DIR/lib/json.sh"
source "$HOOK_DIR/lib/checks.sh"
payload="$(cat)"
active="$(printf '%s' "$payload" | json_field '.stop_hook_active')"
[ "$active" = "true" ] && exit 0
# Clean worktree -> nothing was changed this session, nothing to verify.
[ -z "$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null)" ] && exit 0
case "$VERIFY_CMD" in
  *'<'*) exit 0 ;;  # not configured yet — the kit ships safe
esac
if ! out="$(cd "$PROJECT_DIR" && bash -c "$VERIFY_CMD" 2>&1)"; then
  printf 'Stop blocked: verification gate failed (%s). Fix before ending the session.\n%s\n' \
    "$VERIFY_CMD" "$out" >&2
  exit 2
fi
exit 0
