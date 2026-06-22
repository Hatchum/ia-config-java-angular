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
Use the `ctx7` CLI to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service -- even well-known ones like React, Next.js, Prisma, Express, Tailwind, Django, or Spring Boot. This includes API syntax, configuration, version migration, library-specific debugging, setup instructions, and CLI tool usage. Use even when you think you know the answer -- your training data may not reflect recent changes. Prefer this over web search for library docs.

Do not use for: refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts.

## Steps

1. Resolve library: `npx ctx7@latest library <name> "<user's question>"` — use the official library name with proper punctuation (e.g., "Next.js" not "nextjs", "Customer.io" not "customerio", "Three.js" not "threejs")
2. Pick the best match (ID format: `/org/project`) by: exact name match, description relevance, code snippet count, source reputation (High/Medium preferred), and benchmark score (higher is better). If results don't look right, try alternate names or queries (e.g., "next.js" not "nextjs", or rephrase the question)
3. Fetch docs: `npx ctx7@latest docs <libraryId> "<user's question>"`
4. Answer using the fetched documentation

You MUST call `library` first to get a valid ID unless the user provides one directly in `/org/project` format. Use the user's full question as the query -- specific and detailed queries return better results than vague single words. Do not run more than 3 commands per question. Do not include sensitive information (API keys, passwords, credentials) in queries.

For version-specific docs, use `/org/project/version` from the `library` output (e.g., `/vercel/next.js/v14.3.0`).

If a command fails with a quota error, inform the user and suggest `npx ctx7@latest login` or setting `CONTEXT7_API_KEY` env var for higher limits. Do not silently fall back to training data.
> Codex only: run Context7 CLI requests outside Codex's default sandbox. If a Context7 CLI command fails with DNS or network errors such as ENOTFOUND, host resolution failures, or fetch failed, rerun it outside the sandbox instead of retrying inside the sandbox.
<!-- context7 -->

<!-- playwright -->
For any change that affects the Angular UI — a layout/styling/rendering bug, a
visual fix, or a feature with a visible surface — use the `playwright` skill to
**see** the result, don't reason from the code alone. A visual change is "done"
only when a screenshot confirms it.

Proactive triggers: the user reports something looking wrong ("the table is
misaligned", "the modal doesn't show", "broken on mobile"), asks to "check how
it looks" / "take a screenshot" / "verify the fix in the UI", or you just edited
a `.component.html`/`.scss`/template that changes what's on screen.

Loop: start the app (`scripts\build` then `ng serve`), capture the current state
with a pinned viewport
(`npx playwright screenshot --viewport-size=1280,800 --wait-for-selector="<sel>" <url> before.png`),
apply the fix, re-capture `after.png`, then **Read the images back** and compare
before claiming success. Use `npx playwright test` for E2E and
`toHaveScreenshot()` for pixel regression. See the `playwright` skill for detail;
fetch exact API via `find-docs` (`ctx7 docs /microsoft/playwright "<question>"`).

Do not use for: backend-only changes, non-visual logic, or unit-testable work
that needs no rendering.
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
| `docs/guide/mcp.md` · `.mcp.json`                                       | Optional MCP servers (GitLab default, GitHub/Duo documented) |
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
