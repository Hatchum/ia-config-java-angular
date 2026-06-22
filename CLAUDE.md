# CLAUDE.md — <PROJECT_NAME>
@AGENTS.md

> The common contract (working style, build/test, commit convention, context7,
> playwright, issue management…) is imported from `AGENTS.md` above. This file
> adds only the **Claude Code-specific** layer: skills and `.claude/rules/`.

## Documentation map (who owns what)
| File | Authoritative for |
|------|-------------------|
| `CLAUDE.md` (this) | Claude Code-specific layer (skills, `.claude/rules/`) |
| `AGENTS.md` | Common contract/index, working style, build/test (imported here) |
| `<angular-module>/CLAUDE.md` (placeholder `frontend/`) | Per-module Angular instructions, loaded on demand |
| `ARCHITECTURE.md` | Module map, layering, dependency direction, data flow |
| `.claude/rules/` | Coding law (Java, Angular) — path-scoped, deterministic |
| `.claude/skills/` (Java) · `<angular-module>/.claude/skills/` (Angular) | On-demand knowledge (one topic per skill) |
| `docs/guide/config.md` | Claude Code config: permissions, hooks, how to run them |
| `scripts/` | Build/test commands — the "green" exit criterion |
| `docs/guide/install.md` | How to drop this kit into a project + placeholders to fill |
| `docs/guide/mcp.md` · `.mcp.json` | Optional MCP servers (GitLab default, GitHub/Duo documented) |
| `docs/README.md` | Documentation index (guide / reference / research) |

## Rules (path-scoped)
Coding law in `.claude/rules/` (repo root), loaded when Claude touches matching
files via each rule's `paths` frontmatter:
| Rule | `paths` scope |
|------|---------------|
| `.claude/rules/java-coding-rules.md` | `**/*.java` |
| `.claude/rules/angular-coding-rules.md` | `**/*.ts`, `**/*.scss`, `**/*.component.html` (content-scoped) |

## Skills (on-demand)
On-demand knowledge, loaded when relevant. Grouped by stack (monorepo pattern):
- **Java** → `.claude/skills/` (repo root): code review, tests, JPA, Spring Boot,
  security, concurrency, design patterns, Maven audit, migration, logging…
- **Angular** → `<angular-module>/.claude/skills/` (placeholder `frontend/`):
  `angular-developer`, `angular-new-app`. Discovered on demand when working on
  files in that module.

The team adds its own Java/Angular skill repos in the matching location.

Helpers for the common workflows defined in `AGENTS.md`:
- **Commit messages** → `git-commit` skill (apply the Conventional Commits rule).
- **Tests** → `test-quality` skill (JUnit 5 + AssertJ + Mockito).
- **Issue triage** → `issue-triage` skill (apply the labelling/SLA defaults).
- **UI verification & docs** → `playwright` + `find-docs` skills.
