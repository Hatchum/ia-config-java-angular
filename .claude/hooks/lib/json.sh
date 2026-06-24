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

# jsonl_append <file> <key1> <val1> [<key2> <val2> ...] — append one JSON object
# as a line, creating the parent dir if needed. Prefers jq (proper escaping),
# falls back to Python, then to naive unescaped output as a last resort —
# mirrors the jq → python → grep fallback chain in json_field above, for the
# same reason (Windows hosts without jq, possibly without a real Python either).
# JSON Lines audit pattern per code.claude.com/docs/en/hooks ("Audit configuration
# changes" example: jq -c '{...}' >> file).
jsonl_append() {
  local file="$1" py
  shift
  mkdir -p "$(dirname "$file")"
  if command -v jq >/dev/null 2>&1; then
    local args=() filter="" key
    while [ "$#" -ge 2 ]; do
      key="$1"
      args+=(--arg "$key" "$2")
      [ -z "$filter" ] || filter+=","
      filter+="$key:\$$key"
      shift 2
    done
    jq -cn "${args[@]}" "{$filter}" >> "$file"
  elif py="$(_hook_python)"; then
    "$py" -c '
import json, sys
pairs = sys.argv[1:]
sys.stdout.write(json.dumps(dict(zip(pairs[0::2], pairs[1::2]))) + "\n")' "$@" >> "$file"
  else
    local line="" key
    while [ "$#" -ge 2 ]; do
      key="$1"
      [ -z "$line" ] || line+=","
      line+="\"$key\":\"$2\""
      shift 2
    done
    printf '{%s}\n' "$line" >> "$file"
  fi
}
