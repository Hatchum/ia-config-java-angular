#!/usr/bin/env bash
# json.sh — extract fields from the hook event JSON (read from stdin).
# Field access prefers jq, then a Python interpreter, then a naive single-line grep.
# Python matters because Codex's apply_patch payload puts a MULTI-LINE patch in
# .tool_input.command, which the grep fallback cannot decode.

# _hook_python — echo a Python interpreter that actually RUNS, or nothing.
# On Windows, `python3` is often a Microsoft Store stub that fails when invoked,
# so we probe each candidate instead of trusting `command -v`.
_hook_python() {
  local p
  for p in python3 python py; do
    if command -v "$p" >/dev/null 2>&1 && "$p" -c '' >/dev/null 2>&1; then
      printf '%s' "$p"
      return 0
    fi
  done
  return 1
}

json_field() {
  # json_field <dotted-path>   (reads JSON from stdin)
  local path="$1" py
  if command -v jq >/dev/null 2>&1; then
    jq -r "$path // empty"
  elif py="$(_hook_python)"; then
    "$py" -c 'import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for k in sys.argv[1].lstrip(".").split("."):
    d = d.get(k) if isinstance(d, dict) else None
    if d is None:
        break
sys.stdout.write("" if d is None else str(d))' "$path"
  else
    local key="${path##*.}"
    grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
      | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'
  fi
}

# hook_changed_files — emit newline-separated paths of files touched by an edit,
# handling BOTH tool payload shapes (reads JSON from stdin):
#   Claude Write/Edit/MultiEdit → .tool_input.file_path (one path)
#   Codex apply_patch           → file markers in .tool_input.command patch text
# Delete markers are intentionally skipped (nothing left to lint/log).
hook_changed_files() {
  local payload fp cmd
  payload="$(cat)"
  fp="$(printf '%s' "$payload" | json_field '.tool_input.file_path')"
  if [ -n "$fp" ]; then
    printf '%s\n' "$fp"
    return 0
  fi
  cmd="$(printf '%s' "$payload" | json_field '.tool_input.command')"
  [ -n "$cmd" ] && printf '%s\n' "$cmd" | tr -d '\r' \
    | sed -nE -e 's/^\*\*\* (Add|Update) File: (.+)$/\2/p' -e 's/^\*\*\* Move to: (.+)$/\1/p'
}
