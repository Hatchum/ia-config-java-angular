# CLAUDE.md — <PROJECT_NAME>

> Operational contract + index, loaded every session. Summarises and points;
> detail lives in the authoritative files below. **Single owner per fact:** if
> this file and an authoritative file disagree, the authoritative file wins.

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

Open `ARCHITECTURE.md` before implementing or changing a module.

## Tech stack
- **Java** `<JAVA_VERSION>` · framework `<FRAMEWORK>` (e.g. Spring Boot / Quarkus / plain)
- **Angular** `<ANGULAR_VERSION>`
- **Build:** Maven multi-module **reactor** (parent POM + Java modules + one
  Angular module, typically via `frontend-maven-plugin`)
- **OS:** Windows

## Module map
Authoritative in `ARCHITECTURE.md`. Summary: `<MODULE_LIST>` — `<ARCHITECTURE>`.
(Filled at install by reading the real parent POM and module layout.)

## Working style
- Respond in `<TEAM_LANGUAGE>`. Write Claude-facing files (config, rules, docs)
  in English.
- Surface decisions that matter — architecture, anything hard to reverse,
  ambiguous trade-offs — with concise reasoning. Don't gate routine, low-stakes
  work; just do it.
- **Verify before declaring done:** build & tests green
  (`scripts\build.*`, `scripts\test.*`).
- **Never** commit secrets, `.env`, or API keys; warn if one appears in a diff.
- Respect the coding law in `.claude/rules/` and the layering in `ARCHITECTURE.md`.

## Build & test (run from repo root)
| Task | Command |
|------|---------|
| Build | `scripts\build.cmd`  ·  `scripts\build.ps1` |
| Test  | `scripts\test.cmd`   ·  `scripts\test.ps1` |

Run the `scripts/` wrappers. "Done" = both green.

### Testing strategy
- Coverage target: `<COVERAGE_TARGET — e.g. 80%>` on core business logic (not
  boilerplate). Tune per project.
- Backend tooling: JUnit 5 + AssertJ + Mockito — see the `test-quality` skill.
- Coverage report (JaCoCo): `mvn jacoco:report` →
  `target/site/jacoco/index.html`.

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

## Commit convention
This project follows [Conventional Commits](https://www.conventionalcommits.org/).
- Format: `type(scope): subject` — imperative mood, subject ≤ 50 chars.
- Common types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `build`, `ci`.
- Reference issues in the body/footer (e.g. `Fixes #123`).
- Generate messages with the `git-commit` skill.
  Example: `fix(plugin-loader): prevent NPE when directory missing`

> Still decided internally (this kit imposes nothing): the **git branching model /
> workflow**.

## Issue management (optional team policy)
Defaults — tune or remove per the team's process (the `issue-triage` skill
helps apply them):
- Label every new issue within 48h.
- Respond to questions within 1 week.
- Close stale issues (>90 days, no activity).

## Resources
- [claude-code-java](https://github.com/decebals/claude-code-java) — Java skill source
- [Claude Code docs](https://code.claude.com/docs)
- [AssertJ docs](https://assertj.github.io/doc/)
- [Conventional Commits](https://www.conventionalcommits.org/)

## Roadmap (optional)
If this project tracks status, the table lives here and is its single source of
truth. `<PLACEHOLDER — omit if unused>`.
