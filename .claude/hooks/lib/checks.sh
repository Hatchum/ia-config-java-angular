#!/usr/bin/env bash
# checks.sh — shared lint/format routing for hooks.
# Fill the *_LINT_CMD placeholders at install (§12 <LINT_COMMANDS>).
# A command still containing "<" is treated as UNCONFIGURED and skipped (exit 0),
# so the kit ships safe until real commands are wired in.

# Java sources. Example: mvn -q -pl :your-module spotless:apply checkstyle:check
JAVA_LINT_CMD='<LINT_COMMANDS: java — e.g. mvn -q spotless:apply checkstyle:check>'
# TS/HTML/SCSS/CSS. The touched file is exposed as $FILE.
# Example: npx eslint --fix "$FILE" && npx prettier --write "$FILE"
WEB_LINT_CMD='<LINT_COMMANDS: web — e.g. npx eslint --fix "$FILE" && npx prettier --write "$FILE">'

run_lint_for_file() {
  local file="$1" cmd=""
  case "$file" in
    *.java)                   cmd="$JAVA_LINT_CMD" ;;
    *.ts|*.html|*.scss|*.css) cmd="$WEB_LINT_CMD" ;;
    *) return 0 ;;  # not a linted type
  esac
  case "$cmd" in
    *'<'*) printf 'hook: lint not configured for %s (fill <LINT_COMMANDS> in checks.sh)\n' "$file" >&2; return 0 ;;
  esac
  FILE="$file" bash -c "$cmd"
}
