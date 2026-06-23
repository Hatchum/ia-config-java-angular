# Prompt — Concevoir la structure agentique (orchestrateur + subagents + workflows) pour le développement de features Java/Angular

> Généré avec le skill `prompt-creator`. Cible : **Claude** · archetype
> **planning** · agent **non orchestré** (pas de `<handoff>` — livrable Markdown
> destiné à `docs/research/agentique.md`). Le prompt est en **anglais**
> (consommé par un agent), ce fichier de présentation est en français.
> Fondé sur l'état du dépôt : `docs/guide/roadmap.md` (Phase 3/4),
> `docs/guide/architecture-biagent.md` §11, `docs/reference/subagents.md`,
> `docs/reference/skills.md`, `docs/reference/workflows.md`.

## Le prompt

```text
<role>
You are a senior Claude Code platform engineer specialized in designing multi-agent developer workflows for Java/Spring + Angular monorepos. Your task is to design and document a **configurable** orchestration layer — workflow(s), subagents, rules, skills, memory — that lets a developer run feature work (and bug fixes) through a Claude Code orchestrator backed by specialized subagents, for the bi-agent (Claude Code + Codex) configuration kit in this repository.
</role>

<context>
This repository is `ia-config-java-angular`, a portable **kit** (not an application) installed into real Java+Angular monorepos. It already ships:
- `AGENTS.md` (single source of instructions) imported by `CLAUDE.md`.
- `.ai/rules/java-coding-rules.md` and `.ai/rules/angular-coding-rules.md` — path-scoped behavioral rules, linked into `.claude/rules/`.
- `.ai/skills/` — ~30 skills (Java: java-code-review, jpa-patterns, spring-boot-patterns, test-quality, concurrency-review, security-audit, etc.; Angular: angular-developer, angular-new-app; meta: prompt-creator, skill-creator, subagent-creator), linked into `.claude/skills/`.
- `.ai/config/permissions.yaml` + `hooks.yaml` → generated into `.claude/settings.json` (and Codex equivalents) by `scripts/sync-config.py`. Hooks already gate lint/format/changelog.
- A documented but **not yet implemented** subagents layer: `docs/reference/subagents.md` (verified against https://code.claude.com/docs/en/sub-agents on 2026-06-22) already lists target subagents — `agent-explore-docs`/`-web`/`-code` (haiku), `agent-security-reviewer` (opus), `agent-code-java`/`-angular` (sonnet) — and `docs/guide/roadmap.md` Phase 3/4 marks "Subagents & Workflows" and "Spécialisation" as the next backlog. `docs/guide/architecture-biagent.md` §11 tracks `.ai/config/subagents.yaml → .claude/agents/*.md` generation as "❌ reste à faire".
- `docs/reference/workflows.md` already documents **several distinct workflow patterns**, not just one: the official EPCT loop (Explore → Plan → Code → Commit), a structured DEBUG workflow (analyze → log → find solutions → propose → fix → verify), the file-per-step workflow-skill pattern (`workflow-dev/`, `workflow-debug/`), the dynamic `Workflow` tool that orchestrates subagents in the background, and an adversarial code-review pass. No `workflow-dev`/`workflow-debug` skill exists yet (tracked in `docs/reference/skills.md`).
- `docs/research/agentique.md` exists but is **empty** — it is the designated landing spot for this design note.

**Critical requirement:** the system must NOT hard-wire a single workflow (e.g. EPCT) as the only option. Different task types need different loops — a feature needs explore→plan→code→verify, a bug needs reproduce→diagnose→fix→regression-test, a review needs an adversarial read-only pass. The orchestration layer must let a team **select and combine** workflows, and **select which subagents** participate in each workflow step, via configuration rather than by rewriting instructions every time.

Ground every claim in either the repository's already-verified reference docs (cited above, fresh as of 2026-06-22) or a freshly fetched official Claude Code doc page; never rely on unsourced training-data recall, since subagent/skill/memory mechanics change across Claude Code releases.
</context>

<instructions>
1. Read before writing: `AGENTS.md`, `CLAUDE.md`, `docs/guide/roadmap.md`, `docs/guide/architecture-biagent.md` (§2, §4, §11), `docs/reference/subagents.md`, `docs/reference/skills.md`, `docs/reference/workflows.md`, `docs/research/prompt-drafts.md`, the contents of `.ai/rules/` and `.ai/skills/`, and `.ai/config/*.yaml`. Build a short inventory of what already exists vs. what is genuinely missing — never propose something that already exists under a different name.
2. Spot-check currency: the existing reference docs were verified on 2026-06-22 (one day before this task). Fetch the official pages they cite (`/sub-agents`, `/skills`, `/memory`, `/hooks`, `/best-practices` on https://code.claude.com/docs/en) only to confirm nothing changed and to fill genuine gaps (e.g., subagent memory semantics, the dynamic `Workflow` tool, Agent Teams) — do not re-derive what is already correctly documented.
3. Catalogue the workflow patterns already available or documented (EPCT, DEBUG, dynamic `Workflow` tool, adversarial review) and identify any genuinely missing pattern needed for full feature-delivery coverage (e.g. a review/refactor-only loop, a TDD-style loop). For each pattern, capture: trigger condition (which task archetype it fits), ordered steps, which step needs a hard pass/fail verification gate, and which subagent role acts at each step.
4. Design a **parameterization mechanism** so the workflow used and the subagents involved are both configurable, not hardcoded:
   - Introduce an abstraction layer of **roles** (e.g. `researcher`, `backend-coder`, `frontend-coder`, `reviewer`) that workflow steps reference, instead of referencing concrete subagent names directly.
   - Define a config structure (e.g. extend `.ai/config/subagents.yaml`, or add `.ai/config/workflows.yaml`) that: (a) declares each workflow as a named, ordered list of role-steps with their verification gate; (b) maps each role to one or more concrete subagents; (c) sets a default workflow per task archetype (planning/feature/bug-fix/review-refactor), overridable per invocation (slash-command argument, skill argument, or explicit user request).
   - Explain how `scripts/sync-config.py` would need to extend to validate and project this config (consistent with its existing "refuse to overwrite without GENERATED header" guard), without committing to writing that script now.
5. Specify each concrete subagent needed for feature work, reusing the names already chosen in `docs/reference/subagents.md` where they fit, and adding only genuinely missing ones: a research/exploration subagent (or family — docs/web/code), a Java backend coding subagent, an Angular frontend coding subagent, plus any role identified in step 3 with no current owner. For each: `name`, `model`, `tools`/`disallowedTools`, which `.ai/skills/*` to preload via the `skills` frontmatter field, which `.ai/rules/*.md` convention file governs it, `memory` setting (`project`/`user`/`local`/none) and why, the `description` wording needed for automatic delegation, and which **role** (from step 4) it fulfills.
6. Map conventions explicitly: the Java subagent (`backend-coder` role) must load `.ai/rules/java-coding-rules.md` plus the relevant Java skills (e.g. java-code-review, jpa-patterns, spring-boot-patterns, test-quality); the Angular subagent (`frontend-coder` role) must load `.ai/rules/angular-coding-rules.md` plus angular-developer/angular-new-app. State this as a direct mapping table, not prose.
7. Cover memory deliberately: distinguish the project-level instruction memory already in place (`AGENTS.md`/`CLAUDE.md` hierarchy) from per-subagent persistent memory (`memory: project|user|local`, `.claude/agent-memory/<name>/`). Recommend which subagents (if any) actually benefit from persistent memory, and which don't (most stateless coding subagents won't).
8. Beyond the explicit request, proactively surface what is missing for a *complete, configurable* feature-delivery loop and add each as a clearly labeled "proposed addition" task: at minimum, evaluate an adversarial code-review subagent/role, extending `scripts/sync-config.py` for the new config, hook-gated verification before "done", and whether Agent Teams (experimental) deserves a future flag. Cross-check each against `docs/guide/roadmap.md` so you extend the backlog instead of duplicating it.
9. Assemble everything into one phased, dependency-ordered task list (continuing the spirit of roadmap.md's Phase 3/4) with an observable acceptance criterion per task, and write it as the full content of `docs/research/agentique.md`, matching the documentation style already used in `docs/reference/*.md` (a "Source vérifiée" header with date and URL, tables over prose, a final sources section).
10. If anything in the existing reference docs turns out to be stale relative to the freshly fetched pages, flag the discrepancy explicitly in the new document instead of silently overwriting the older file.
</instructions>

<reasoning>
Think it through before writing: first build the inventory (step 1) and the currency check (step 2) in full. Then design the role/workflow abstraction (steps 3-4) BEFORE picking concrete subagent names (step 5) — the abstraction must come first, or the design will silently re-hardcode one workflow. Do not propose a subagent, rule mapping, memory setting, or workflow step that is not traceable to either an existing file in this repo or a cited doc URL.
</reasoning>

<output_format>
Produce a single Markdown document — the full content of `docs/research/agentique.md` — with these sections, in order:
1. A "Source vérifiée" header line (docs cited + verification date), mirroring `docs/reference/subagents.md`.
2. **Context** — one paragraph on why this plan exists and what backlog it advances.
3. **Inventory** — table of what already exists (file/skill/rule) vs. what is genuinely new.
4. **Workflows catalogue** — one row per workflow pattern (name, trigger/archetype, ordered steps, verification gate(s)).
5. **Roles & parameterization** — the role abstraction, the config schema (file + fields) that lets a team pick a workflow and bind roles to subagents, and the default archetype→workflow mapping.
6. **Subagents** — one table row per subagent: name, model, tools, preloaded skills, governing rule file, memory setting, role fulfilled, delegation description.
7. **Memory strategy** — short section distinguishing instruction memory vs. per-subagent persistent memory.
8. **Phased task list** — numbered tasks with `depends_on` and an observable acceptance criterion each, split into explicit asks vs. proposed additions.
9. **Open questions** — anything genuinely ambiguous (e.g., whether to invest in Agent Teams now, or in a GUI/CLI to switch workflows).
10. **Sources** — every doc URL actually fetched or relied upon.

Do not wrap this in a `<handoff>` envelope: this is a one-off design document meant to be committed to the repo and read by humans, following the same convention as the other `docs/reference/*.md` files — not a step consumed by an automated orchestrator.
</output_format>

<input>
{{ADDITIONAL_CONSTRAINTS}}  <!-- optional: team size, parallelism budget, model-cost ceiling, preferred default workflow, or anything else to weigh in; leave empty if none -->
</input>

Before writing the final document, verify: the workflow used and the subagents involved are genuinely configurable (no single workflow is hardcoded as "the" loop); every subagent/skill/rule path you reference actually exists or is clearly marked "to create"; every Claude Code mechanic you describe (subagent frontmatter fields, memory levels, hook events) is grounded in a cited doc or an already-verified reference file; and the phased task list does not duplicate an item already tracked in `docs/guide/roadmap.md` under a different name.
```

## Design notes

- **Tuné pour :** Claude · planning · java+angular au niveau kit · non orchestré
  (pas de `<handoff>` — voir justification ci-dessous).
- **Choix clés :**
  - **Workflow non figé** : remplace l'instruction "concevoir une boucle EPCT"
    par un catalogue de patterns déjà documentés (EPCT, DEBUG, `Workflow`
    dynamique, revue adverse) + une **couche de rôles** (`researcher`,
    `backend-coder`, `frontend-coder`, `reviewer`) que les workflows référencent
    au lieu de noms de subagents en dur — c'est ce qui rend le système
    paramétrable sur le workflow ET sur les subagents en même temps.
  - L'abstraction rôle → subagent est **conçue avant** le choix des subagents
    concrets (étape 3-4 avant étape 5), pour éviter de re-figer un seul mapping.
  - Mécanisme de configuration proposé : étendre `.ai/config/subagents.yaml`
    (ou ajouter `.ai/config/workflows.yaml`) avec un mapping archetype→workflow
    par défaut, surchageable à l'invocation — cohérent avec le pattern
    "source YAML unique → génération" déjà utilisé dans le kit pour permissions
    et hooks.
  - `<handoff>` **volontairement omis** : livrable = document Markdown humain
    suivant la convention `docs/reference/*.md` du dépôt, pas une étape
    consommée par un orchestrateur automatisé.
- **Hypothèses faites :**
  - Le livrable cible reste `docs/research/agentique.md` (actuellement vide).
  - La paramétrisation est conçue ici (ce prompt produit un **plan**, pas le
    code de `sync-config.py` ni les fichiers `.claude/agents/*.md` eux-mêmes).

## Quality check (10/10)
✓ Role & objective ✓ Clear task ✓ Context ✓ Structure ✓ Reasoning
— (skipped : les fichiers `docs/reference/*.md` existants servent d'exemple
de style, déjà cités) Examples
✓ Output contract ✓ Variables ✓ Guardrails ✓ Self-verification
