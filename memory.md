# memory.md — Deep-analysis knowledge base of this repo (for future optimization work)

> Written 2026-07-01 by Claude after a full-repo analysis requested by the user;
> updated the same day after implementing P1 (generator extension), P4
> (verify-on-stop gate) and the doc-drift/hygiene fixes listed in §9.
> Purpose: everything an agent must know about this project to later **improve the
> configuration's effectiveness**. Facts below were verified by reading the files,
> not inferred. Update this file when the kit's structure changes.

## 1. What this repo IS

A **portable, bi-agent AI configuration kit** (a *template*, not an application)
to be installed into existing **Java + Angular Maven multi-module monorepos**
(Windows-first). It drives two coding agents from one source of truth:
**Claude Code** (Anthropic) and **Codex** (OpenAI). Its purpose: feature
development and bug fixing with **deep human–agent collaboration** (reactive
HITL escalation, human checkpoints, verification gates).

Core principle: **share the intent, generate the residual.**
- ~80% "intelligent content" (instructions, skills, rules) is fully shared via
  the native `@AGENTS.md` import and the open `SKILL.md` standard + Windows
  junctions.
- The tool-specific residue (permissions, hooks wiring, execution policy) is
  **generated** from abstract YAML in `.ai/config/` by `scripts/sync-config.py`.
- Every generated file carries the marker `GENERATED FROM .ai/config — DO NOT
  EDIT DIRECTLY`; the generator refuses to overwrite files lacking it
  (`_safe_write`/`_has_generated_marker`).

⚠️ "Rules" is a **false friend**: `.ai/rules/*.md` = behavioral instructions
(markdown, path-scoped); `.codex/rules/*.rules` = **Starlark execution policy**
(the Codex equivalent of Claude permissions).

## 2. Layer map (who owns what)

| Layer | Files | Nature |
|---|---|---|
| Instructions | `AGENTS.md` (source, read natively by Codex; tag convention `> Codex only:` / `> Claude only:`) ← imported by `CLAUDE.md` (`@AGENTS.md` + Claude-specific layer). `frontend/CLAUDE.md` = per-module placeholder | hand-authored |
| Canonical shared dir | `.ai/skills/` (single copy of ~30 skills), `.ai/rules/` (java/angular coding rules), `.ai/config/` (5 YAML sources), `.ai/eval-workspaces/` (skill-creator benchmark artifacts, kept out of skills/) | hand-authored |
| Claude side | `.claude/skills` + `.claude/rules` = **junctions** to `.ai/`; `.claude/settings.json` (GENERATED); `.claude/hooks/` (shared portable scripts .sh+.ps1); `.claude/agents/` (7 hand-authored subagents); `.claude/agent-memory/` (seeded MEMORY.md for the 2 reviewers, git-versioned) | mixed |
| Codex side | `.agents/skills` = junction to `.ai/skills`; `.codex/config.toml`, `.codex/hooks.json`, `.codex/rules/execution-policy.rules` (all GENERATED) | generated |
| Generator | `scripts/sync-config.py` (+ `.ps1`/`.cmd` wrappers) | code |
| Build/test criterion | `scripts/build.{cmd,ps1}` (`mvn -q -T1C clean install`), `scripts/test.{cmd,ps1}` (`mvn test` + `npm test` in `$AngularDir`, default `frontend`) | code |
| Docs | `docs/guide/` (operate the kit), `docs/reference/` (verified Claude Code manual, 11 sheets), `docs/research/` (design provenance) | hand-authored |
| Placeholder target files | `.config/ARCHITECTURE.md` (module map template), `frontend/` (Angular module placeholder), `skills-lock.json` (tracks upstream of the 2 Angular skills, github `angular/skills`) | template |
| Unsorted input | `a_trier/` — ~40 PNG screenshots from a training course on agentic systems/skills/MCP/memory (fed the `image-ocr` skill evals) | raw material |

## 3. The orchestration layer (the heart of the kit)

Designed in `docs/research/agentique.md` (v2, 2026-06-24, replaces a v1 that
allowed dynamic workflows). **Load-bearing decision:** official dynamic
workflows have "No mid-run user input" and Agent Teams have no human-escalation
channel → **in-session subagents are the ONLY execution mechanism**. Parallel =
several Agent calls in one message; sequential = across turns. Dynamic
workflows/Agent Teams remain a *proposed future addition* for bulk low-HITL work
(task P10/P7).

### Data model (3 YAML files; since 2026-07-01 the generator cross-validates
### workflows/subagents and projects the ROLE BINDING block — task P1 done)
- `.ai/config/workflows.yaml` — 3 workflows keyed by archetype:
  - `workflow-dev` (feature, EPCT): explore(researcher, parallel) →
    implement-backend(backend-coder) ∥ implement-frontend(frontend-coder) →
    review(reviewer). Verification gates: mvn/build green; ng test/build green;
    no high-severity finding.
  - `workflow-debug` (bug-fix): analyze → fix (backend|frontend coder chosen at
    dispatch) → review, all sequential; regression test red-before/green-after.
  - `workflow-review` (review-refactor): single reviewer step, standalone on a diff/PR.
  - `default_archetype_workflow` maps archetype→workflow; `planning: null`
    (deliberately unbound). Overridable per invocation by the human.
- `.ai/config/subagents.yaml` — 4 layers:
  (a) `roles:` researcher→[agent-explore-code/docs/web], backend-coder→[agent-code-java],
  frontend-coder→[agent-code-angular], reviewer→[agent-review-adversarial, agent-security-reviewer];
  (b) `sop:` (role × archetype) → `anatomy_source` anchor in
  `.ai/skills/prompt-creator/references/dev-orchestration.md` + one-line `flavor`
  (e.g. backend-coder/feature = TDD-flavored);
  (c) `team_overrides:` → `.ai/config/sop-overrides.yaml` (empty template,
  `add_steps`/`remove_steps`/`replace_steps` — teams patch SOPs without touching
  any other file);
  (d) `hitl:` — the STATUS-token convention (below).
- `.ai/config/sop-overrides.yaml` — `overrides: {}`, hand-edited by teams, never generated.

### HITL convention (mechanical, regex-on-last-line)
Every subagent must end with exactly one line:
`STATUS: completed` | `STATUS: blocked — <reason>` | `STATUS: needs_clarification — <question>`.
Orchestrator rule: completed (and reported verification=pass) → next step;
blocked/needs_clarification → `AskUserQuestion` BEFORE any further dispatch;
missing/malformed/contradicted → fail-safe treat as needs_clarification.
Rationale: `AskUserQuestion` is unavailable to subagents (verified 2026-06-24),
so escalation is necessarily carried by the orchestrator (main session).
Plain text (not XML) because subagents return free text — adapted from the
`<handoff>` XML contract in `dev-orchestration.md` (used for orchestrated
prompts generated by `prompt-creator`).

### The 7 subagents (`.claude/agents/*.md`, hand-authored)
| Agent | Model | Tools | Preloaded skills | memory | Role |
|---|---|---|---|---|---|
| agent-explore-code | haiku | Read,Grep,Glob | — | — | researcher |
| agent-explore-docs | haiku | Read,Bash,Grep,Glob | find-docs | — | researcher |
| agent-explore-web | haiku | WebSearch,WebFetch | — | — | researcher |
| agent-code-java | sonnet | R,E,W,Bash,Grep,Glob | java-code-review, jpa-patterns, spring-boot-patterns, test-quality | — | backend-coder |
| agent-code-angular | sonnet | R,E,W,Bash,Grep,Glob | angular-developer | — | frontend-coder |
| agent-review-adversarial | sonnet | Read,Grep,Glob | clean-code, solid-principles, test-quality | project | reviewer (routine, diff+acceptance-criteria only, fresh context) |
| agent-security-reviewer | opus | Read,Grep,Glob,Bash | security-audit, concurrency-review | project | reviewer (explicit escalation only: auth/crypto/payment/deserialization/user-input file I/O) |

Common anatomy of each agent file: `<!-- BEGIN ROLE BINDING ... -->` HTML
comment (GENERATED from subagents.yaml by sync-config.py since P1; includes
"Also bound to this role:" siblings), role prose, governing
rules/skills, "Load your SOP" section (reads subagents.yaml →
sop.<role>.<archetype>, then sop-overrides.yaml), mandatory verification before
`completed`, and the STATUS block. Coders must show the real test/build command
+ result in the summary; the orchestrator treats a `completed` without shown
verification as malformed.

Memory strategy (3 levels, documented in agentique.md): (1) CLAUDE.md/AGENTS.md
= rules; (2) native auto-memory of the main session (machine-local, nothing to
configure); (3) `memory: project` ONLY for the two reviewers
(`.claude/agent-memory/<name>/MEMORY.md`, git-shared, to remember adjudicated
false positives). Explicit decision: NO memory for explorers/coders (stale
memory could bias future implementations).

### Workflow skills (orchestrator-side packaging)
`.ai/skills/workflow-dev/` and `.ai/skills/workflow-debug/`: SKILL.md + 5 step
files each (file-per-step pattern to avoid loading everything at once; read one
at a time). The SKILL explicitly says: *you (the main session) are the
orchestrator; never delegate the orchestration itself* (AskUserQuestion
unavailable to subagents). workflow-debug maps the official DEBUG pattern with
2 human checkpoints carried by the orchestrator: step-2-propose (human picks
between 2–3 candidate fixes) and step-4-verify (final human confirmation).

## 4. Hooks & observability

Sources in `.ai/config/hooks.yaml` (two sections because matcher vocabularies
differ: Claude edits = `Write|Edit|MultiEdit`, Codex = `apply_patch`; scripts
are shared, wiring is generated per tool; Claude-only fields `shell`/`if`,
Codex-only `timeout`/`statusMessage` are filtered by the generator).

Scripts in `.claude/hooks/` (every hook has a `.sh` AND `.ps1` twin; portable
root resolution `${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}`):
- `lint-format` (PostToolUse on edits) — delegates to `lib/checks.{sh,ps1}`,
  the ONLY place lint commands live. Shipped **inert**: commands containing `<`
  (unfilled placeholders `JAVA_LINT_CMD`/`WEB_LINT_CMD`) → skip exit 0. Exit 2
  feeds linter output back to Claude.
- `pre-commit-lint` (PreToolUse Bash, `git commit`) — lints staged files, exit 2 blocks.
- `log-changes` (PostToolUse edits) — JSONL `event: tool_edit` →
  `.claude/logs/agent-activity.jsonl` with `agent_type`/`agent_id` attribution
  ("main"/"-" when from the main session). Replaces legacy
  `.claude/changes.local.log` (frozen, still gitignored).
- `log-agent-lifecycle` (SubagentStart/SubagentStop) → `.claude/logs/agent-runs.jsonl`.
- `log-worktree-snapshot` (Stop + SubagentStop) — `git status --porcelain` scan,
  `event: worktree_snapshot`, catches edits made via raw Bash that PostToolUse
  can't see. Stop supports no matcher → entry omits the key (generator was
  fixed for that: `_build_hooks` no longer requires `matcher`).
- `lib/json.{sh,ps1}` — `json_field` + `jsonl_append` with fallback chain
  jq → detected Python (avoids Windows Store `python3` stub) → naive. This
  machine has no jq (Python fallback validated).
- `verify-on-stop` (Stop, added 2026-07-01 = task P4) — the deterministic gate:
  blocks (exit 2) ending a session on a dirty worktree when `VERIFY_CMD`
  (lib/checks.{sh,ps1}, placeholder `<VERIFY_COMMANDS>`) fails. Ships inert;
  loop-protected via `stop_hook_active`; skips when worktree is clean.
- Design rationale: two JSONL files = two human questions ("who ran, when" vs
  "what changed, by whom"); logs written ONLY by deterministic hooks, never by
  the LLM (option C rejected). Logs are observability-after-the-fact;
  `verify-on-stop` is the hard gate against a false `STATUS: completed` (once
  `VERIFY_CMD` is filled at install).

## 5. Permissions

`.ai/config/permissions.yaml` = single canonical list in Claude syntax.
deny: read of build artifacts (target/dist/build), destructive fs/disk/shutdown/
privilege commands (deliberately broad across Git Bash/PowerShell/cmd because
the team shell isn't fixed yet), and **all direct DB clients** (psql/mysql/
sqlite3/mongo/redis-cli/… — policy: verify persisted state through the app
layer, see api-testing skill). ask: git history-rewriting (push --force, reset
--hard, clean). allow: mvn/gradle wrappers, safe git + `git commit`/`git push`.
Generator projects: verbatim → settings.json; `Bash(...)`-only → Starlark
substring lists DENY/ASK/ALLOW with a `filter()` function. Read/Edit entries
are Claude-only by design.

## 6. Skills inventory (`.ai/skills/`, ~30)

- **Java** (each with SKILL.md + README, sourced from decebals/claude-code-java):
  java-code-review, test-quality, jpa-patterns, spring-boot-patterns,
  security-audit, concurrency-review, design-patterns, solid-principles,
  clean-code, maven-dependency-audit, java-migration, logging-patterns,
  api-contract-review, architecture-review, performance-smell-detection,
  changelog-generator, git-commit, issue-triage.
- **Angular**: angular-developer (large references/ dir: signals, forms, DI,
  routing, SSR, testing…), angular-new-app. Upstream tracked by
  `skills-lock.json` (github angular/skills). Also exposed per-module via
  `frontend/.claude/skills/` (symlinks to `.agents/skills`).
- **CLI-tool skills (MCP replacement)**: find-docs (ctx7 CLI / Context7),
  playwright (visual verification + E2E; AGENTS.md mandates screenshot-verified
  "done" for UI changes), api-testing (HTTPie+jq).
- **Meta**: prompt-creator (10-point rubric, model playbooks, templates,
  dev-orchestration.md with `<handoff>` contract + archetype anatomies — the
  SOP anatomy source), skill-creator (full eval harness: agents/, scripts/
  run_eval.py etc.), subagent-creator, find-skills, firecrawl-deep-research,
  image-ocr (its 2 eval iterations produced by skill-creator benchmarking live
  in `.ai/eval-workspaces/image-ocr/`, deliberately outside skills/).
- **Workflows**: workflow-dev, workflow-debug (see §3).

MCP was **removed** by decision (README): every external tool is a skill
invoking a CLI. `docs/guide/mcp.md` is historical.

## 7. Docs

- `docs/guide/`: architecture-biagent.md (THE reference for the bi-agent design;
  §11 = done/todo state), install.md (copy list, placeholder table, linter
  activation, symlink/junction strategy), config.md (permissions/hooks/subagents
  human reference; launch Claude from repo root or settings aren't loaded),
  mcp.md (historical), roadmap.md (backlog consolidé + phase order; Phases 3–4
  marked done).
- `docs/reference/`: 11 verified sheets (claude-md, rules, skills, subagents,
  workflows, models, hooks, lsp, context-management, automation,
  agent-system-logs) — a generic, source-verified Claude Code manual.
- `docs/research/`: agentique.md (orchestration design v2, full provenance +
  task list D1–P10), prompt-structure-agentique.md (the respecialized
  prompt that generated the orchestration layer), prompt-drafts.md (archive),
  rag.md (decision: NO RAG — agentic search suffices), subagent-creator-research/
  -prompt.md (kit-internal artifacts, not copied to targets).

## 8. Current state (done vs pending)

Done: instructions/skills/rules sharing; permissions+hooks sources + generator
+ 4 generated outputs; DB-access ban; 7 subagents + role/SOP/HITL YAML layer;
workflow-dev/debug/review; agent-activity/agent-runs JSONL logging; reviewer
agent-memory seeded.

**Done 2026-07-01 (this session):**
- **P1** ✅ — `sync-config.py` now has `validate_orchestration()` (roles exist;
  agent files on disk; sop keys; default_archetype_workflow targets; hitl
  complete; team_overrides parses) and `project_role_bindings()` (regenerates
  ONLY the `<!-- BEGIN ROLE BINDING ... -->` block in each agent file;
  idempotent; inserts after frontmatter if block missing). Tested: negative
  validation fails loudly; second run rewrites nothing. Keep output ASCII —
  a `→` in a print crashed under the cp1252 console.
- **P4** ✅ — `verify-on-stop.{sh,ps1}` wired on `Stop` (see §4). Inert until
  `VERIFY_CMD`/`$VerifyCmd` filled in lib/checks.
- Doc drift fixed: install.md §1 rewritten to the real layout (`.ai/` canonical,
  no `.mcp.json`, sync-config step, junctions), §5 corrected (links point to
  `.ai/skills`, not `.agents/`); config.md hooks table completed (6 hooks) +
  subagents section updated (kit ships 7); mcp row in AGENTS.md/CLAUDE.md marked
  historical; mcp.md no longer cites the deleted rule file.
- Context dedup: AGENTS.md ctx7 + playwright blocks condensed to trigger
  paragraphs pointing at `find-docs`/`playwright` skills (full protocol lives
  there); `.ai/rules/context7.md` DELETED (was loaded every session on top of
  the AGENTS.md copy).
- Hygiene: `.ai/skills/image-ocr-workspace/` moved to
  `.ai/eval-workspaces/image-ocr/` (+ README explaining why: a workspace's
  `skill-snapshot/SKILL.md` polluted skill discovery); `__pycache__` purged and
  gitignore generalized.
- Status docs synced: architecture-biagent.md §6+§11, roadmap.md, agentique.md
  P1/P4 rows.

**Still pending:**
- **P5**: real-world test of /workflow-dev + /workflow-debug incl. an observed
  AskUserQuestion escalation. **P6**: pilot a real sop-overrides entry.
- **P7/P8**: proposed-only — dynamic workflow for bulk audits; Agent Teams doc.
- **P9**: Codex TOML projection of subagents (no documented Codex equivalent yet).
- Real Codex test (skills discovery `.agents/skills`, hooks.json, Starlark) never run.
- Global `~/ai-config/` hub layout not done. Placeholders unfilled by design.
- `a_trier/` (~40 course screenshots) awaits triage; `image-ocr` skill exists
  to transcribe them (content task, deliberately not done during the fix pass).
- Open questions (agentique.md): merge the 2 reviewers if double review proves
  rarely needed? skills wrapper vs direct workflows.yaml read?
- prompt-creator: Option B subagent eval still pending; prompts default to
  English (they feed an orchestrator) — from persistent memory.

## 9. Session-environment gotchas (for future runs on this machine)

- `python` on PATH is the Microsoft Store stub — use `py -3` (the kit's own
  hooks already detect this; `scripts/sync-config.ps1` calls bare `python`,
  which works from PowerShell but not from Git Bash).
- No `jq` installed — the hooks' Python fallback is what actually runs.
- Console is cp1252: keep generator/hook output ASCII.

## 10. Conventions binding any future work here

- Respond in French to the user; agent-facing files in English.
- Conventional Commits (`type(scope): subject`, ≤50 chars, imperative).
- Never edit generated files directly — edit `.ai/config/` + rerun
  `scripts\sync-config.ps1`. Never commit secrets. "Done" = scripts/build +
  scripts/test green. Don't invent architecture: this is a template with
  `<PLACEHOLDER>`s filled at install time only.
