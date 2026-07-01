# AGENTS.md — <PROJECT_NAME>

> Operational contract + index, loaded every session. Summarises and points;
> detail lives in the authoritative files below. **Single owner per fact:** if
> this file and an authoritative file disagree, the authoritative file wins.
>
> Scope: this file holds the **common** contract shared by every agent (Codex &
> Claude Code). Claude Code-specific guidance (skills, `.claude/rules/`) lives in
> `CLAUDE.md`, which imports this file via `@AGENTS.md`.

---

## Agent-tag convention (read first)

Codex reads **only** this file; Claude Code reads it too (via `@AGENTS.md` in
`CLAUDE.md`). Codex has no `@import`, so any rule meant for a single agent must
live here, **explicitly tagged**. Everything untagged is common and binds every
agent.

| Tag | Who must obey | Who must ignore |
|-----|---------------|-----------------|
| _(untagged)_ | every agent | — |
| `> Codex only:` | Codex (OpenAI Code) | Claude Code |
| `> Claude only:` | Claude Code | Codex |

Rules:
- Put a one-line tagged blockquote **immediately above** the instruction it
  governs (or open a tagged section with it).
- Keep agent-specific blocks short; if a whole topic is Claude-only (skills,
  `.claude/rules/`), put it in `CLAUDE.md` instead of tagging it here.
- If you read a tag that names the *other* agent, skip that instruction.

Example:

> Codex only: run Context7 CLI requests outside Codex's default sandbox.

---

<!-- context7 -->
**Library/framework documentation — never answer from training data.** For any
question about a library, framework, SDK, API, CLI tool, or cloud service (even
well-known ones like Spring Boot or Angular — API syntax, configuration,
migration, library-specific debugging), fetch current docs with the `ctx7` CLI
via the **`find-docs` skill** — it owns the full protocol (resolve the library
ID first, then fetch docs; ≤3 commands per question; never fall back silently
to training data on a quota error). Prefer it over web search for library docs.
Not for: refactoring, business-logic debugging, code review, or general
programming concepts.
> Codex only: run Context7 CLI requests outside Codex's default sandbox. If a Context7 CLI command fails with DNS or network errors such as ENOTFOUND, host resolution failures, or fetch failed, rerun it outside the sandbox instead of retrying inside the sandbox.
<!-- context7 -->

<!-- playwright -->
**UI changes are verified visually, never from code alone.** For any change
with a visible surface in the Angular UI (layout/styling/rendering bug, visual
fix, feature with an on-screen effect — or whenever the user says something
"looks wrong" or asks to "check how it looks"), use the **`playwright` skill**:
start the app, screenshot before/after with a pinned viewport, **read the
images back** and compare before claiming success (`npx playwright test` +
`toHaveScreenshot()` for E2E/pixel regression). A visual change is "done" only
when a screenshot confirms it. Not for: backend-only changes or non-visual,
unit-testable work.
<!-- playwright -->


## Documentation map (who owns what)
| File                                                                    | Authoritative for |
|-------------------------------------------------------------------------|-------------------|
| `AGENTS.md` (this)                                                      | Common contract/index, working style, where things live |
| `CLAUDE.md`                                                             | Claude Code-specific layer (skills, `.claude/rules/`); imports this file |
| `<angular-module>/AGENTS.md` (placeholder `frontend/`)                  | Per-module Angular instructions, loaded on demand |
| `ARCHITECTURE.md`                                                       | Module map, layering, dependency direction, data flow |
| `.codex/rules/` · `.claude/rules/`                                      | Coding law (Java, Angular) — path-scoped, deterministic (per agent) |
| `docs/guide/config.md`                                                  | Agent config: permissions, hooks, how to run them |
| `scripts/`                                                              | Build/test commands — the "green" exit criterion |
| `docs/guide/install.md`                                                 | How to drop this kit into a project + placeholders to fill |
| `docs/guide/mcp.md`                                                     | MCP servers — **historical**: replaced by CLI-invoking skills (`find-docs`, `playwright`, `api-testing`) |
| `docs/README.md`                                                        | Documentation index (guide / reference / research) |

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
- Respond in `<TEAM_LANGUAGE>`. Write agent-facing files (config, rules, docs)
  in English.
- **Spec-driven feature work.** Before implementing any feature: explore the
  code first, then ask the human **every** clarifying question the exploration
  leaves open (batch them; concrete options, not vague open questions), then
  get a short spec approved — goal, scope in/out, observable acceptance
  criteria — in `docs/specs/<date>-<slug>.md`. Implement against those
  criteria, nothing more. Never substitute a guess for a question about scope,
  expected behavior, or a trade-off. (Full loop: `feature` skill.)
- Surface decisions that matter — architecture, anything hard to reverse,
  ambiguous trade-offs — with concise reasoning. Don't gate routine, low-stakes
  work; just do it.
- **Verify before declaring done:** build & tests green
  (`scripts\build.*`, `scripts\test.*`).
- **Never** commit secrets, `.env`, or API keys; warn if one appears in a diff.
- Respect the coding law in the agent rules dir (`.codex/rules/` · `.claude/rules/`)
  and the layering in `ARCHITECTURE.md`.

## Build & test (run from repo root)
| Task | Command |
|------|---------|
| Build | `scripts\build.cmd`  ·  `scripts\build.ps1` |
| Test  | `scripts\test.cmd`   ·  `scripts\test.ps1` |

Run the `scripts/` wrappers. "Done" = both green.

### Testing strategy
- Coverage target: `<COVERAGE_TARGET — e.g. 80%>` on core business logic (not
  boilerplate). Tune per project.
- Backend tooling: JUnit 5 + AssertJ + Mockito.
- Coverage report (JaCoCo): `mvn jacoco:report` →
  `target/site/jacoco/index.html`.

## Commit convention
This project follows [Conventional Commits](https://www.conventionalcommits.org/).
- Format: `type(scope): subject` — imperative mood, subject ≤ 50 chars.
- Common types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `build`, `ci`.
- Reference issues in the body/footer (e.g. `Fixes #123`).
  Example: `fix(plugin-loader): prevent NPE when directory missing`

> Still decided internally (this kit imposes nothing): the **git branching model /
> workflow**.

## Issue management (optional team policy)
Defaults — tune or remove per the team's process:
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
