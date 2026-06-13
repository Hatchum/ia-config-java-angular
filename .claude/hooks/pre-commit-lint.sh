#!/usr/bin/env bash
# PreToolUse(Bash): if the command is a `git commit`, lint staged files first.
# Contract: exit 2 BLOCKS the commit and returns the report to Claude.
# Inert while <LINT_COMMANDS> are unconfigured (run_lint_for_file skips → never blocks).
set -euo pipefail
HOOK_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks"
source "$HOOK_DIR/lib/json.sh"
source "$HOOK_DIR/lib/checks.sh"
cmd="$(json_field '.tool_input.command')"
case "$cmd" in *git*commit*) ;; *) exit 0 ;; esac
failed=0; report=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if ! out="$(run_lint_for_file "$f" 2>&1)"; then
    failed=1; report+="$out"$'\n'
  fi
done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)
if [ "$failed" -ne 0 ]; then
  printf 'Commit blocked: staged files failed lint.\n%s\n' "$report" >&2
  exit 2
fi
exit 0
