# CLAUDE.md — <PROJECT_NAME>
@AGENTS.md

## Documentation map (who owns what)
| File | Authoritative for |
|------|-------------------|
| `CLAUDE.md` (this) | Index/contract, working style, where things live |
| `<angular-module>/CLAUDE.md` (placeholder `frontend/`) | Per-module Angular instructions, loaded on demand |
| `ARCHITECTURE.md` | Module map, layering, dependency direction, data flow |
| `.claude/rules/` | Coding law (Java, Angular) — path-scoped, deterministic |
| `.claude/skills/` (Java) · `<angular-module>/.claude/skills/` (Angular) | On-demand knowledge (one topic per skill) |
| `docs/CONFIG.md` | Claude Code config: permissions, hooks, how to run them |
| `scripts/` | Build/test commands — the "green" exit criterion |
| `docs/INSTALL.md` | How to drop this kit into a project + placeholders to fill |
| `docs/MCP.md` · `.mcp.json` | Optional MCP servers (GitLab default, GitHub/Duo documented) |