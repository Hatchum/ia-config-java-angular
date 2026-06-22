# Prompt — Créer le skill `subagent-creator` (via `skill-creator`)

> Généré avec le skill `prompt-creator`. Cible : **Claude** · archetype
> **feature** · agent **orchestré** (contrat `<handoff>`). Le prompt est en
> **anglais** (consommé par un agent, pas lu par un humain).
> Fondé sur la recherche : voir [`subagent-creator-research.md`](./subagent-creator-research.md).

## Le prompt

```text
<role>
You are a senior Claude Code skill engineer working as a sub-agent under an
orchestrator. Your task is to create a new, production-quality skill named
`subagent-creator` by USING the existing `skill-creator` skill — not by writing
SKILL.md by hand. The `subagent-creator` skill must help its future users author
high-quality Claude Code subagents (the Markdown agent files in `.claude/agents/`),
and it must accept the target subagent's LLM model as an explicit parameter.
</role>

<context>
This repository is a Claude Code configuration kit. Skills live in `.ai/skills/`
(the `.claude/` directory is a symlink to `.ai/`). You will deliver the new skill
at `.ai/skills/subagent-creator/`.

Two existing skills are central — read them before acting:
- `.ai/skills/skill-creator/SKILL.md` — the meta-skill you MUST drive to build
  `subagent-creator`. Follow its loop: capture intent → write SKILL.md (name +
  "pushy" description + body) → optional evals/test cases → iterate. Reuse its
  scripts (e.g. `scripts/quick_validate.py`, `scripts/package_skill.py`) instead
  of reinventing them.
- `.ai/skills/find-docs/SKILL.md` — the Context7 (`ctx7`) workflow, in case you
  need to re-verify any API detail against current docs.

Authoritative domain knowledge has ALREADY been researched and distilled in
`docs/subagent-creator-research.md` (sources: official Anthropic Claude Code
subagent docs + OpenAI "building agents" guidance). Treat that file as the source
of truth for what a subagent is and which fields exist; re-fetch via `find-docs`
only to resolve a specific doubt. The essentials you must encode into the skill:

- A Claude Code subagent = a Markdown file (`.claude/agents/<name>.md`) with YAML
  frontmatter + a body that becomes the subagent's system prompt. It runs in an
  isolated context and returns only a summary; Claude delegates to it based on its
  `description`.
- Frontmatter fields: `name` (required, kebab-case), `description` (required — the
  delegation trigger), `tools` (allowlist, least-privilege), `disallowedTools`,
  `model` (`sonnet`/`opus`/`haiku`/`fable`/full ID/`inherit`; default `inherit`),
  `permissionMode`, `skills`, `mcpServers`, `hooks`, `memory`, `maxTurns`,
  `effort`, `isolation`, `color`, `background`, `initialPrompt`.
- Design principles (Anthropic ∩ OpenAI): one focused task per subagent; a
  specific `description` is what drives delegation (add "use proactively" to push
  it); least-privilege tools; isolated context returning a concise summary;
  explicit output format; explicit guardrails and "when unsure" behavior; version
  project subagents. System-prompt anatomy: Role → "When invoked" workflow →
  domain checklist → output format.

Why this matters: the orchestrator will route real work to subagents created by
this skill. A vague description, over-broad tool access, or a wrong model wastes
tokens and weakens delegation — so the skill must make those choices deliberate.
</context>

<instructions>
1. Read `docs/subagent-creator-research.md`, then `.ai/skills/skill-creator/SKILL.md`
   in full. Do not start writing the new skill until you understand skill-creator's
   workflow; you will operate THROUGH it.
2. Drive `skill-creator` to scaffold `subagent-creator` at `.ai/skills/subagent-creator/`.
   Author a SKILL.md whose `description` is specific and slightly "pushy" so it
   triggers whenever a user wants to create, design, or scaffold a Claude Code
   subagent / custom agent (even when they don't say the word "subagent").
3. Make the skill PARAMETER-DRIVEN. It must collect and validate at least these
   inputs, with sensible defaults and inference (ask only on critical ambiguity):
   - `model` (REQUIRED) — the subagent's LLM. Accept `sonnet`, `opus`, `haiku`,
     `fable`, a full model ID, or `inherit`. Default `inherit`. Give cost/capability
     guidance (haiku = fast/cheap exploration; sonnet = balanced; opus = hardest
     reasoning). Map it to the `model` frontmatter field.
   - `name` (REQUIRED) — kebab-case identifier → `name`.
   - `description`/trigger (REQUIRED) — when Claude should delegate → `description`.
   - `purpose` + system-prompt content → the Markdown body (Role → workflow →
     checklist → output format).
   - `tools` (optional, least-privilege allowlist) and `disallowedTools` → tool fields.
   - `scope` (project `.claude/agents/` default, or user `~/.claude/agents/`).
   - advanced/optional pass-throughs documented in the research file
     (`permissionMode`, `skills`, `memory`, `color`, `maxTurns`, `isolation`, hooks).
   The skill must clearly state which params are required vs inferred, and document
   how each maps to the generated subagent's frontmatter/body.
4. The skill's OUTPUT must be a ready-to-save subagent file: valid YAML frontmatter
   + a focused system-prompt body following the research's anatomy, plus a one-line
   note on where to place it and that a session restart loads disk edits.
5. Bake the official best practices into the skill's guidance (focused scope,
   specific description, least-privilege tools, deliberate model choice, explicit
   output/guardrails), explaining the WHY rather than issuing bare MUSTs.
6. Validate the new skill with skill-creator's tooling (run
   `python -m scripts.quick_validate .ai/skills/subagent-creator` from the
   skill-creator directory, or the equivalent it documents). Optionally seed 2-3
   realistic test prompts in `evals/evals.json`. Clean up scratch files.
</instructions>

<reasoning>
Work through it inside <thinking> tags before creating files: confirm
skill-creator's exact workflow and scripts; decide the final parameter list and
defaults from the research file; sketch the SKILL.md description and the body
template the skill will emit; only then build.
</reasoning>

<output_format>
End your turn with exactly one <handoff> block and nothing after it:
<handoff>
  <status>completed | blocked | needs_clarification</status>
  <summary>One sentence: what was built.</summary>
  <confidence>high | medium | low</confidence>
  <changes>
    <change path=".ai/skills/subagent-creator/SKILL.md" action="created">
      what it does and the params it exposes (incl. model)
    </change>
    <!-- list any other created files: evals/evals.json, references/, scripts/ -->
  </changes>
  <verification>
    <command>python -m scripts.quick_validate .ai/skills/subagent-creator</command>
    <result>pass | fail | not_run</result>
  </verification>
  <next_actions>
    <action>e.g. run skill-creator's eval loop, or optimize the description.</action>
  </next_actions>
  <!-- include <blockers> only if status=blocked,
       <open_questions> only if status=needs_clarification -->
</handoff>
</output_format>

Before emitting the handoff, confirm the skill validates, that `model` is a
required parameter wired to the `model` frontmatter field, and that the skill was
produced via skill-creator (not hand-rolled). If skill-creator's workflow is
genuinely unclear or a required input is ambiguous, stop and report
status=needs_clarification rather than guessing.
```

## Design notes

- **Tuned for:** Claude · feature · skill-authoring (stack `other`) · orchestrated
  agent (handoff: **yes**).
- **Key choices:**
  - Le prompt **impose le passage par `skill-creator`** (étape 1-2 + vérification
    finale) au lieu d'écrire le SKILL.md à la main — c'est l'exigence centrale.
  - La recherche est **externalisée** dans `docs/subagent-creator-research.md` et
    citée comme source de vérité : le prompt reste lisible et l'agent garde la
    connaissance officielle sous la main.
  - Le **paramètre `model`** est explicitement **requis** (demande utilisateur),
    avec valeurs autorisées + guidage coût/capacité, et son mapping frontmatter.
- **Assumptions I made:**
  - Emplacement de livraison `.ai/skills/subagent-creator/` (cohérent avec le repo,
    `.claude` → symlink `.ai`).
  - Vérification via `quick_validate.py` de skill-creator ; evals optionnelles.
  - Scope par défaut = projet (`.claude/agents/`).

## Quality check (10/10)
✓ Role & objective ✓ Clear task ✓ Context ✓ Structure ✓ Reasoning
— (skipped: input *is* the concrete spec — research file + skill-creator) Examples
✓ Output contract (`<handoff>`) ✓ Variables (params explicites) ✓ Guardrails
✓ Self-verification
