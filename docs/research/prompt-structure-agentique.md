# Prompt — Concevoir et générer la structure agentique (orchestrateur + subagents en session + workflows + SOP paramétrables) pour le développement de features Java/Angular

> Généré avec le skill `prompt-creator`, puis **respécialisé** le 2026-06-24
> (toujours via `prompt-creator`) pour : (1) restreindre le mécanisme
> d'exécution multi-agent aux **subagents en session** (le seul compatible
> avec l'escalade humaine réactive demandée — voir Contexte), (2) ajouter un
> axe de **paramétrage des SOP** (procédure d'un rôle = f(rôle, workflow/
> archétype) + surcouche de configuration par équipe), (3) étendre la portée :
> le prompt ne se contente plus d'un document de conception, il doit aussi
> **générer réellement** `.ai/config/workflows.yaml`, `.ai/config/subagents.yaml`
> et les fichiers `.claude/agents/*.md`.
>
> Cible : **Claude** · archétype **planning + feature** (conception ET
> implémentation des artefacts de config) · agent **non orchestré** (pas de
> `<handoff>` — ce prompt reste une exécution ponctuelle pilotée par un humain
> dans une session Claude Code, pas une étape consommée par un orchestrateur
> automatisé en amont ; voir justification dans les Design notes).
> Fondé sur l'état du dépôt : `docs/guide/roadmap.md` (Phase 3/4),
> `docs/guide/architecture-biagent.md` §11, `docs/reference/subagents.md`
> (vérifié 2026-06-22), `docs/reference/skills.md`, `docs/reference/workflows.md`
> (vérifié 2026-06-22), `.ai/skills/prompt-creator/references/dev-orchestration.md`,
> et trois pages officielles fraîchement vérifiées le 2026-06-24 :
> [Run agents in parallel](https://code.claude.com/docs/en/agents),
> [Orchestrate dynamic workflows](https://code.claude.com/docs/en/workflows),
> [Configure permissions](https://code.claude.com/docs/en/permissions). Le
> prompt est en **anglais** (consommé par un agent), ce fichier de présentation
> est en français.

## Le prompt

```text
<role>
You are a senior Claude Code platform engineer specialized in designing multi-agent developer workflows for Java/Spring + Angular monorepos. Your task is to design, document, AND actually generate a configurable orchestration layer — in-session subagents, role-based workflows with a parallel/sequential dispatch policy, role×archetype SOP parameterization with a team-level override layer, and reactive human-in-the-loop (HITL) escalation — for the bi-agent (Claude Code + Codex) configuration kit in this repository. The deliverable is not a paper plan alone: by the end of this task, real files must exist on disk.
</role>

<context>
This repository is `ia-config-java-angular`, a portable **kit** (not an application) installed into real Java+Angular monorepos. It already ships:
- `AGENTS.md` (single source of instructions) imported by `CLAUDE.md`.
- `.ai/rules/java-coding-rules.md` and `.ai/rules/angular-coding-rules.md` — path-scoped behavioral rules, linked into `.claude/rules/`.
- `.ai/skills/` — ~30 skills (Java: java-code-review, jpa-patterns, spring-boot-patterns, test-quality, concurrency-review, security-audit, etc.; Angular: angular-developer, angular-new-app; meta: prompt-creator, skill-creator, subagent-creator), linked into `.claude/skills/`.
- `.ai/config/permissions.yaml` + `hooks.yaml` → generated into `.claude/settings.json` (and Codex equivalents) by `scripts/sync-config.py`. Both files open with a "DO NOT import directly — generator: scripts/sync-config.py" header; any new config file you add must follow that same convention. **Neither `.ai/config/subagents.yaml` nor `.ai/config/workflows.yaml` exists yet** — you are authoring them for the first time, not extending pre-existing files. `.claude/agents/` is currently empty — you are populating it for the first time too.
- A documented subagents layer: `docs/reference/subagents.md` (verified against https://code.claude.com/docs/en/sub-agents on 2026-06-22) lists target subagents — `agent-explore-docs`/`-web`/`-code` (haiku), `agent-security-reviewer` (opus), `agent-code-java`/`-angular` (sonnet) — and confirms, from the official page, that **`AskUserQuestion`, `EnterPlanMode`, `ExitPlanMode` (except `permissionMode: plan`), `ScheduleWakeup`, and `WaitForMcpServers` are NOT available to subagents**. This is load-bearing for the HITL design below: only the orchestrator (the main Claude Code session) can ask the human a question; a subagent can only return a summary.
- `docs/reference/workflows.md` (verified 2026-06-22) documents the official EPCT loop, a DEBUG workflow, the file-per-step skill pattern, and a brief mention of "dynamic workflows" and an adversarial review pass — but predates a fuller official comparison page.
- `docs/research/agentique.md` exists but is **empty** — the landing spot for the design half of this deliverable.

**Resolved mechanism constraint (read this before designing anything):** three official, freshly-fetched pages (2026-06-24) describe four distinct ways Claude Code parallelizes agent work — [Run agents in parallel](https://code.claude.com/docs/en/agents) compares subagents, agent view (background sessions), agent teams (experimental, peer-to-peer, disabled by default), and dynamic workflows. [Orchestrate dynamic workflows](https://code.claude.com/docs/en/workflows) specifies that a dynamic workflow is a JS script the runtime executes in the background, scaling to **up to 16 concurrent agents and 1,000 agents total per run** — but its "Behavior and limits" table states verbatim: *"No mid-run user input — Only agent permission prompts can pause a run. For sign-off between stages, run each stage as its own workflow."* This directly conflicts with this kit's requirement (below) that the orchestrator must be able to ask the human a question **the moment** a subagent reports a problem, not only at a pre-planned stage boundary. Agent teams offer no documented equivalent escalation path either (peer-to-peer messaging between teammates, not a route to the human). **Therefore: this design must use in-session subagents as the only execution mechanism** — Claude (the orchestrator) dispatches subagents turn by turn; issuing several independent `Task`/`Agent` calls in one message is the parallel case, issuing calls across turns (each depending on the prior result) is the sequential case; nesting up to depth 5 is supported per the verified `docs/reference/subagents.md`. Dynamic workflows and Agent Teams are explicitly **out of scope for execution** in this design — record them only as a future "proposed addition" for bulk, low-HITL work (e.g. a repo-wide audit), never as the default loop.

**Critical requirement (unchanged from the original brief):** the system must NOT hard-wire a single workflow (e.g. EPCT) as the only option. A team must be able to **select and combine** workflows, and **select which subagents** participate in each workflow step, via configuration rather than by rewriting instructions every time.

**New requirement — reactive HITL escalation:** the orchestrator must ask the human via `AskUserQuestion` whenever a subagent's returned summary signals it is blocked or needs clarification — not on a fixed cadence (not "after every step", not "only before irreversible actions"). Since a subagent returns free text to the parent context rather than a parseable envelope, you must define a minimal, unambiguous status-token convention every subagent's system prompt is instructed to end its summary with (e.g. a one-line `STATUS: completed` / `STATUS: blocked — <reason>` / `STATUS: needs_clarification — <question>" tag), so the orchestrator can deterministically detect when to escalate versus when to continue. Reuse the vocabulary already proven in `.ai/skills/prompt-creator/references/dev-orchestration.md`'s `<handoff>` contract (`status`, `<blockers>`, `<open_questions>`) as the source of truth for the token's semantics, adapted to plain text since subagents here are not asked to emit XML.

**New requirement — SOP parameterization:** the procedure a subagent follows (its SOP) must vary along two independent axes at once: (a) which workflow/archetype invoked the role — e.g. the `backend-coder` role follows a TDD-flavored SOP under a `feature` workflow but a reproduce→root-cause→fix→regression-test SOP under a `bug-fix` workflow, reusing the per-archetype anatomies already defined in `.ai/skills/prompt-creator/references/dev-orchestration.md`; and (b) a team/project-level override layer that can customize or extend SOP steps **without editing** the subagent's `.claude/agents/*.md` file or the workflow definition itself. Design this as data (file(s) + fields), not prose.

Ground every claim in either the repository's already-verified reference docs (cited above) or a freshly fetched official Claude Code doc page; never rely on unsourced training-data recall, since subagent/skill/memory/workflow mechanics change across Claude Code releases.
</context>

<instructions>
1. Read before writing: `AGENTS.md`, `CLAUDE.md`, `docs/guide/roadmap.md`, `docs/guide/architecture-biagent.md` (§2, §4, §11), `docs/reference/subagents.md`, `docs/reference/skills.md`, `docs/reference/workflows.md`, `docs/research/prompt-drafts.md`, the contents of `.ai/rules/`, `.ai/skills/` (especially `prompt-creator/references/dev-orchestration.md`), and `.ai/config/*.yaml`. Confirm directly (don't assume) whether `.ai/config/subagents.yaml`, `.ai/config/workflows.yaml`, and any file under `.claude/agents/` exist at the moment you run this — build the inventory from what you actually observe.
2. Spot-check currency: re-confirm `/sub-agents`, `/agents`, `/workflows`, and `/permissions` on https://code.claude.com/docs/en (the four facts this design leans on hardest: subagent tool unavailability list, the dynamic-workflow no-mid-run-input limit, the 16/1,000 concurrency caps, and the permission-mode/hook mechanics) before relying on them — fetch only what's genuinely uncertain; do not re-derive what the repo's already-verified reference docs correctly state.
3. Catalogue the workflow patterns this kit will actually run (EPCT-style feature loop, DEBUG loop, adversarial review pass, plus any genuinely missing pattern for full feature-delivery coverage). For each: trigger condition/archetype, ordered role-steps, which steps are safe to dispatch in parallel (independent) vs must be sequential (dependent), and which step carries a hard pass/fail verification gate. State explicitly, as a named decision, that dynamic workflows and Agent Teams are excluded from the execution mechanism for the reason given in the context, and that this is new information versus the briefer mention in `docs/reference/workflows.md` (verified 2026-06-22) — flag it as an addition, don't silently patch over it.
4. Design, in this order, BEFORE naming a single concrete subagent: (a) the role abstraction (e.g. `researcher`, `backend-coder`, `frontend-coder`, `reviewer`) that workflow steps reference instead of concrete subagent names; (b) the SOP-parameterization function `sop(role, archetype) → procedure` plus the team-level override file that can patch/extend steps without touching workflow or agent-file definitions; (c) the HITL status-token convention every subagent's summary must end with, and exactly how/when the orchestrator reacts to it with `AskUserQuestion`. Only after (a)-(c) are settled, define the config schema: author `.ai/config/workflows.yaml` (named, ordered role-steps per workflow, each step's parallel/sequential marker and verification gate, a default archetype→workflow mapping overridable per invocation) and `.ai/config/subagents.yaml` (role→subagent bindings, role×archetype→SOP source, team-override file path). Follow the existing "GENERATED header / do not hand-edit downstream" convention already used by `permissions.yaml`/`hooks.yaml`, and explain — without committing to writing the script — how `scripts/sync-config.py` would need to extend to validate and project this new config.
5. Specify each concrete subagent needed, reusing names already chosen in `docs/reference/subagents.md` where they fit and adding only genuinely missing ones (a research/exploration subagent or family, a Java backend coding subagent, an Angular frontend coding subagent, plus any role from step 3 with no current owner). For each: `name`, `model`, `tools`/`disallowedTools`, preloaded `.ai/skills/*` (via the `skills` frontmatter field), governing `.ai/rules/*.md`, `memory` setting and why, which SOP source it loads (per the step-4 schema), the end-of-turn status-token instruction it must contain, the `description` wording needed for automatic delegation, and which role it fulfills.
6. Map conventions explicitly as a table, not prose: the Java subagent (`backend-coder` role) loads `.ai/rules/java-coding-rules.md` plus the relevant Java skills (java-code-review, jpa-patterns, spring-boot-patterns, test-quality); the Angular subagent (`frontend-coder` role) loads `.ai/rules/angular-coding-rules.md` plus angular-developer/angular-new-app.
7. Cover memory deliberately: distinguish the project-level instruction memory already in place (`AGENTS.md`/`CLAUDE.md` hierarchy) from per-subagent persistent memory (`memory: project|user|local`, `.claude/agent-memory/<name>/`). Recommend which subagents (if any) actually benefit from persistent memory, and which don't.
8. Surface what's missing beyond the explicit request as clearly labeled "proposed addition" tasks: at minimum, an adversarial code-review subagent/role, extending `scripts/sync-config.py` for the new config, hook-gated verification before "done", and a future flag for dynamic workflows/Agent Teams once (and only if) the kit needs bulk, lower-granularity-HITL work. Cross-check each against `docs/guide/roadmap.md` so you extend the backlog instead of duplicating it.
9. Now generate the real artifacts — do not stop at description. Write `.ai/config/workflows.yaml` and `.ai/config/subagents.yaml` to disk matching the step-4 schema, and write one `.claude/agents/<name>.md` file per subagent from step 5, each with valid frontmatter (per the field list verified in `docs/reference/subagents.md`) and a system prompt embedding its role, its rule/skill preloads, its SOP-loading instruction, and the status-token convention. Confirm each YAML file parses and each agent file's frontmatter is syntactically valid before moving on.
10. Assemble everything into one phased, dependency-ordered task list (continuing the spirit of roadmap.md's Phase 3/4) with an observable acceptance criterion per task — mark the tasks this very run already completed (the files from step 9) as done, and list what remains as backlog. Write the full design narrative (sections below) as the content of `docs/research/agentique.md`, matching the documentation style already used in `docs/reference/*.md` (a "Source vérifiée" header with date and URLs, tables over prose, a final sources section). If anything in the existing reference docs turns out stale relative to a freshly fetched page, flag the discrepancy explicitly instead of silently overwriting the older file.
</instructions>

<reasoning>
Think it through before writing or creating any file: build the inventory (step 1) and the currency check (step 2) in full first. Decide the execution-mechanism restriction (step 3) before designing roles. Design the role/SOP/HITL abstraction (step 4) BEFORE picking concrete subagent names (step 5) or writing a single file to disk (step 9) — naming subagents or writing agent files before the schema is final means rewriting them. Do not propose a subagent, rule mapping, memory setting, workflow step, or config field that is not traceable to either an existing file in this repo or a cited doc URL.
</reasoning>

<output_format>
Produce two kinds of deliverables in this run:

**A.** Real files on disk: `.ai/config/workflows.yaml`, `.ai/config/subagents.yaml`, and one `.claude/agents/<name>.md` per subagent designed in step 5.

**B.** A single Markdown document — the full content of `docs/research/agentique.md` — with these sections, in order:
1. A "Source vérifiée" header line (every doc cited or fetched + verification date), mirroring `docs/reference/subagents.md`.
2. **Context** — why this plan exists, what backlog it advances, and the headline finding that restricts execution to in-session subagents (cite the exact dynamic-workflow limitation).
3. **Inventory** — table of what already existed vs. what this run created.
4. **Workflows catalogue** — one row per pattern (name, trigger/archetype, ordered steps, which are parallel-eligible vs sequential, verification gate(s)); explicit note that dynamic workflows/Agent Teams are out of scope for execution, with the reason.
5. **Roles & SOP parameterization** — the role abstraction, the `sop(role, archetype)` schema, the team-override layer, and the default archetype→workflow mapping — as the actual fields used in the `.yaml` files you wrote.
6. **HITL escalation mechanism** — the status-token convention, exactly how the orchestrator detects it, and when it calls `AskUserQuestion` (citing the subagent tool-unavailability constraint).
7. **Subagents** — one row per subagent: name, model, tools, preloaded skills, governing rule file, memory setting, role, SOP source, status-token note, delegation description.
8. **Memory strategy** — instruction memory vs. per-subagent persistent memory.
9. **Artifacts produced** — exact list of every file this run created/modified, one line each on what it contains.
10. **Phased task list** — numbered tasks with `depends_on` and an observable acceptance criterion each, split into "done this run" vs. backlog vs. proposed additions.
11. **Open questions** — anything genuinely ambiguous (e.g., whether to invest in Agent Teams later, or build a CLI to switch workflows).
12. **Sources** — every doc URL actually fetched or relied upon.

Do not wrap section B in a `<handoff>` envelope: it's a one-off design document meant to be committed to the repo and read by humans, following the convention of other `docs/reference/*.md` files — not a step consumed by an automated orchestrator.
</output_format>

<input>
{{ADDITIONAL_CONSTRAINTS}}  <!-- optional: team size, parallelism budget, model-cost ceiling, preferred default workflow, or anything else to weigh in; leave empty if none -->
</input>

Before finishing, verify: the in-session-subagents-only restriction is justified by the cited limitation, not merely asserted; the SOP-parameterization schema has real field names you actually used in the `.yaml` files, not just prose describing the idea; the HITL status-token convention is precise enough that an orchestrator could mechanically decide to call `AskUserQuestion` versus continue; every subagent/skill/rule path you reference actually exists or was just created by this run; the three artifact types (the two `.yaml` files, the `.claude/agents/*.md` files, and `agentique.md`) are all actually written to disk, not only described; and the phased task list does not duplicate an item already tracked in `docs/guide/roadmap.md` under a different name.
```

## Design notes

- **Tuné pour :** Claude · planning + feature (conception + génération de
  fichiers réels) · java+angular au niveau kit · non orchestré (pas de
  `<handoff>`).
- **Pourquoi pas de `<handoff>` malgré la génération de vrais fichiers :**
  l'agent qui exécute ce prompt reste invoqué directement par un humain dans
  une session Claude Code (bootstrap ponctuel), pas par un orchestrateur
  automatisé qui aurait besoin de router son résultat vers une étape
  suivante — le `<handoff>` n'apporterait rien ici, contrairement à un
  sub-agent de feature/bug-fix routine.
- **Choix clés :**
  - **Mécanisme restreint aux subagents en session** : décision tranchée par
    une vraie contrainte documentée (`/workflows` : *"No mid-run user input —
    … For sign-off between stages, run each stage as its own workflow"*), pas
    par préférence arbitraire — les dynamic workflows et Agent Teams sont
    explicitement écartés de l'exécution parce qu'ils ne supportent pas
    l'escalade humaine réactive exigée, et relégués en "proposed addition"
    pour un usage futur à plus grande échelle et plus faible granularité HITL.
  - **Escalade HITL = réactive, pas planifiée** : ce n'est pas un point
    d'arrêt fixe entre chaque étape ni seulement avant les actions
    irréversibles — c'est l'orchestrateur qui détecte, via une convention de
    token de statut en fin de résumé du subagent, qu'il doit appeler
    `AskUserQuestion` (outil indisponible aux subagents eux-mêmes, donc
    nécessairement porté par l'orchestrateur).
  - **SOP = f(rôle, archétype) + surcouche équipe** : un même rôle change de
    procédure selon le workflow qui l'invoque (réutilise les anatomies
    d'archétype déjà définies dans `dev-orchestration.md`), et une équipe peut
    surcharger des étapes sans toucher ni au fichier subagent ni à la
    définition du workflow — deux axes de configuration indépendants et
    cumulables, comme demandé.
  - **Portée étendue à la génération réelle** : le prompt ne produit plus
    seulement `docs/research/agentique.md` — il doit aussi écrire
    `.ai/config/workflows.yaml`, `.ai/config/subagents.yaml` (tous deux
    inexistants à ce jour) et les fichiers `.claude/agents/*.md`
    correspondants, avant de documenter ce qu'il a produit.
- **Hypothèses faites :**
  - Le statut de fin de tour des subagents reste du texte libre se terminant
    par une convention `STATUS: …` plutôt qu'un XML `<handoff>` structuré —
    cohérent avec le fait que les subagents renvoient un résumé à la session
    parente, pas une enveloppe parseable par défaut.
  - `scripts/sync-config.py` n'est pas réécrit par ce prompt ; son extension
    pour valider/projeter les nouveaux fichiers YAML reste documentée comme
    tâche à faire, pas implémentée ici.

## Quality check (10/10)
✓ Role & objective ✓ Clear task ✓ Context ✓ Structure ✓ Reasoning
— (skipped : les fichiers `docs/reference/*.md` existants et
`dev-orchestration.md` servent d'exemple de style/contrat déjà cités) Examples
✓ Output contract ✓ Variables ✓ Guardrails ✓ Self-verification
