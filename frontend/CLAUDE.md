# frontend/ — Angular module instructions (PLACEHOLDER)

Per-module instructions, loaded on demand when Claude works on files in this
Angular module (Claude Code monorepo pattern). The repo-root `CLAUDE.md` still
applies; this only adds module-specific context.

- **Stack:** Angular `<ANGULAR_VERSION>`.
- **Build / test:** from this directory — `<e.g. npm ci && npm test>`, or via the
  root Maven reactor if wired with `frontend-maven-plugin`. See root `scripts/`.
- **Coding law:** the path-scoped `.claude/rules/angular-coding-rules.md` at the
  repo root governs this module.
- **Skills:** Angular skills live in `./.claude/skills/`, discovered on demand
  while you work here.

Fill the placeholders at install (see the kit's `docs/guide/install.md`). If the real
Angular module uses a different directory name, this file moves with it.
