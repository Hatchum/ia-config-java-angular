---
name: prompt-creator
description: Generate elite, enterprise-grade prompts that drive a software-development orchestrator agent (and its sub-agents) across the dev lifecycle — task planning, feature development, bug analysis and fixing, refactoring, and code review — for stacks like MQL5 trading bots, Java/Spring, and Angular. Synthesizes the official prompt-engineering guidance of Anthropic, OpenAI, and Google into a 10-point quality rubric, adapts to the target model, and by default emits a structured <handoff> output contract the orchestrator can parse. Use this skill whenever the user wants to create, write, generate, design, improve, or optimize a prompt, system prompt, sub-agent prompt, or meta-prompt — especially for planning a feature, implementing code, diagnosing or fixing a bug, or orchestrating dev agents — even when they give only a rough task description or a few parameters.
---

# Prompt Creator

Turn whatever a user gives you — a feature request, a bug report, a one-line
idea, or a filled parameter list — into a **top-tier prompt** of the quality a
senior prompt engineer at Anthropic, OpenAI, or Google would ship.

**Primary use case:** prompts that drive a **software-development orchestrator
agent** and its sub-agents across the dev lifecycle — planning tasks, developing
features, analyzing and fixing bugs, refactoring, reviewing code — for stacks
like **MQL5** trading bots, **Java/Spring**, and **Angular**. Because the output
is consumed by an orchestrator (not read by a human), generated prompts default
to **English** and end with a structured **`<handoff>`** block the orchestrator
can parse. The skill still works for general (non-dev) prompts — just drop the
dev-specific pieces.

The skill does two jobs at once:
1. **Build** a structured, model-adapted prompt from the user's parameters.
2. **Score** it against a 10-point quality rubric and revise until it passes, so
   the output is reliably excellent rather than a first draft.

The 10-point rubric is the spine of this skill — the distilled intersection of
the three companies' published best practices. See `references/quality-rubric.md`
for the full criteria with good/bad contrasts and source attribution.

## When to use

Trigger on any request to author or upgrade a prompt — especially for dev work:
- "Write a prompt for my orchestrator that plans this feature."
- "Make a sub-agent prompt that fixes this bug in our Spring service."
- "I need a prompt to implement a trailing stop in our MQL5 EA."
- "Generate a prompt that reviews this Angular component."
- "Improve / optimize this prompt." · "How should I phrase this for Claude/GPT?"

Even if the user only describes the *task* (a feature, a bug, a plan), that's
enough to start — fill the gaps with smart defaults (Step 2) rather than blocking.

## Workflow

These steps mirror how Anthropic's prompt generator, the OpenAI prompt optimizer,
and Google's automatic-prompt-engineering loop all work: gather intent → draft
against best practices → self-evaluate → refine.

### Step 1 — Collect the parameters

Map whatever the user gave you onto the set below. Accept input in *any* form — a
sentence, a bullet list, a half-filled template, or an existing prompt to improve.

| Parameter | What it is | Required? |
|-----------|-----------|-----------|
| **Task / objective** | What the target agent should accomplish | Yes (the one thing you truly need) |
| **Task archetype** | `planning` · `feature` · `bug-fix` · `review/refactor` · `other` | No — infer from the request |
| **Tech stack** | `mql5` · `java` · `angular` · `other` | No — infer; ask only if it changes the prompt materially |
| **Target model** | `claude` · `openai` (GPT) · `gemini` · `agnostic` | No — default `agnostic` |
| **Role / persona** | Expert identity the agent should adopt | No — infer from the task |
| **Context / source** | Code, stack trace, requirements, conventions, files | No |
| **Input variables** | Dynamic data fed in at runtime | No |
| **Output format** | What the agent returns | No — default: structured **`<handoff>`** for the orchestrator |
| **Examples** | Sample input→output pairs (few-shot) | No |
| **Constraints / guardrails** | What to avoid, edge cases, "when unsure" behavior | No |
| **Language** | Language of the *generated prompt* | No — default: **English** |
| **Is it an orchestrated agent?** | Will the prompt run under an orchestrator? | No — default **yes** (so include the handoff) |

### Step 2 — Fill the gaps (don't block)

A great prompt generator solves the "blank page problem" — it produces a strong
draft from minimal input. Infer missing parameters from the task instead of
interrogating the user:
- Derive a fitting **expert role** from the objective and stack (e.g. "senior
  Spring Boot engineer", "MQL5 expert-advisor developer").
- Pick the **task archetype** from the verb ("plan" → planning, "fix" → bug-fix,
  "implement/add" → feature, "review/clean up" → review/refactor).
- Propose plausible **edge-case handling** and **guardrails** (failing build,
  missing repro, ambiguous requirements).

Track every assumption — you'll surface them as "Design notes" so the user can
correct anything you guessed. Only stop to ask when a *critical* ambiguity would
change the whole prompt (e.g. the objective itself is unclear, or the stack
materially changes the approach and you genuinely can't infer it). One focused
question is fine; an interrogation is not.

### Step 3 — Select the model playbook

Read the relevant section of `references/model-playbooks.md` and apply it:
- **`claude`** → XML-tagged sections, role in the system prompt, "think step by
  step", examples in `<example>` tags, longform data (code/traces) at the top.
  Do **not** use last-turn prefill (unsupported on current Claude models).
- **`openai`** → Markdown-header sections (Role & Objective, Instructions,
  Reasoning Steps, Output Format, Examples, Context); most important rules last;
  for agents add the persistence / tool-calling / planning reminders.
- **`gemini`** → simple clear structure, *instructions over constraints*, JSON
  output, suggested temperature/config.
- **`agnostic`** (default) → XML-tagged sections; XML parses cleanly across all
  three families, so it's the safest cross-model choice.

### Step 4 — Apply the dev archetype, stack, and handoff contract

For dev work (the primary use case), read `references/dev-orchestration.md`. It
defines:
- the **`<handoff>` output contract** — the structured block the agent emits so
  the orchestrator can route the result (status, summary, artifacts/plan,
  commands to verify, next actions, blockers/questions). This is the **default
  output format** unless the user wants something else.
- the **task archetypes** — what a `planning`, `feature`, `bug-fix`, or
  `review/refactor` prompt must contain (e.g. a bug-fix prompt needs
  reproduce → root-cause → minimal fix → regression test).
- **stack notes** — conventions and how to verify for `mql5`, `java`, `angular`
  (e.g. Java → `mvn test`; Angular → `ng test`; MQL5 → Strategy Tester, no
  standard unit framework).

Drop the handoff only for genuinely one-off, non-orchestrated prompts — and note
that choice in the design notes.

### Step 5 — Assemble the prompt

Build from the skeleton below, dropping any section the task doesn't need. Adapt
delimiters to the chosen playbook. Detailed skeletons live in
`references/templates.md`; dev worked examples (with handoff) live in
`references/dev-orchestration.md`.

```
[ROLE & OBJECTIVE]   You are <expert role for the stack>. Your task is to <objective>.
[CONTEXT]            Code/trace/requirements, conventions, and why it matters.
[INSTRUCTIONS]       Numbered, sequential, positive; archetype-specific steps.
[REASONING]          How to think it through (analyze first / think step by step).
[EXAMPLES]           1–5 relevant, diverse, tagged input→output pairs (optional).
[OUTPUT FORMAT]      The <handoff> contract (default) — or whatever the user wants.
[INPUT]              Variables as {{double_brackets}}; longform code/data near top.
[VERIFICATION]       "Before emitting the handoff, run <checks> and confirm."
```

Use `{{double_brackets}}` for every dynamic value so the prompt is a reusable
**template**, not a one-off.

### Step 6 — Self-score against the 10-point rubric

Walk the prompt through all ten marks (full detail in `quality-rubric.md`):

1. **Role & objective** — expert persona + one-line mission.
2. **Crystal-clear task** — passes the "confused colleague" test. *(Anthropic's golden rule.)*
3. **Context & motivation** — background, source material, and the *why*.
4. **Clean structure** — sectioned with model-appropriate delimiters.
5. **Reasoning guidance** — think step-by-step / a process, when it helps.
6. **Concrete examples** — relevant, diverse, delimited few-shot (when useful).
7. **Explicit output contract** — for dev, the `<handoff>` block; for data, a schema.
8. **Reusable variables** — `{{placeholders}}`; long inputs near the top.
9. **Positive framing + guardrails** — what *to do*; edge cases; "when unsure".
10. **Self-verification** — the agent checks its work before finalizing.

If any applicable mark fails, revise and re-check.

### Step 7 — Deliver

Present the result in the output format below.

## Output format (how you reply to the user)

````markdown
## Your prompt

```text
<the full, copy-paste-ready prompt template, including the <handoff> contract>
```

## Design notes
- **Tuned for:** <model> · <archetype> · <stack> · orchestrated agent (handoff: yes/no)
- **Key choices:** <1–3 bullets on the important structural decisions>
- **Assumptions I made:** <each inferred parameter — so the user can correct it;
  write "none — you specified everything" if nothing was inferred>

## Quality check (10/10)
✓ Role & objective ✓ Clear task ✓ Context ✓ Structure ✓ Reasoning
✓ Examples ✓ Output contract ✓ Variables ✓ Guardrails ✓ Self-verification
<if any mark was intentionally skipped, replace its ✓ with "— (skipped: reason)">

## Recommended config <!-- include only for gemini/openai or when relevant -->
<temperature / top-p suggestion for the task type, per Google's guidance>
````

Keep the prompt itself the hero of the response. The notes and checklist are
short — they prove the quality and expose your assumptions.

## Principles that override the mechanics

- **Generate the prompt in English by default.** The generated prompt is consumed
  by an LLM or agent (the orchestrator), not read by the user — and English is the
  most robust, best-tested language for model instructions, as well as the language
  all three vendors' guidance is written in. Switch the prompt's language only when
  the user explicitly asks, or when the prompt clearly drives an end-user-facing
  experience in another language. Keep *talking to the user* in their own language.
- **Default to the `<handoff>` contract for dev prompts.** An orchestrator needs a
  parseable result. Drop it only for one-off, non-orchestrated prompts.
- **Don't over-build.** A simple task gets a simple prompt. The skeleton is a menu,
  not a mandate — a tight bug-fix prompt that nails the objective beats a 40-line
  template stuffed with empty sections.
- **Explain, don't dictate, inside the generated prompt.** Models generalize from a
  stated *reason*, so prefer "Run the tests because the orchestrator gates on a
  green build" over a bare "ALWAYS run tests."
- **The rubric is the bar, not a checklist to parrot.** Use it to find what's weak
  and fix it, not to pad the prompt with ceremony.

## Reference files

- `references/quality-rubric.md` — the 10 marks in depth: good vs. poor, and which
  company's guidance backs each. Read when judging or justifying quality.
- `references/model-playbooks.md` — per-model conventions (delimiters, structure,
  config, agent reminders) for Claude, GPT, Gemini. Read in Step 3.
- `references/dev-orchestration.md` — the `<handoff>` output contract, the dev task
  archetypes (planning / feature / bug-fix / review-refactor), stack notes
  (MQL5 / Java / Angular), and dev worked examples. Read in Step 4.
- `references/templates.md` — ready-to-fill skeletons per model family. Read in
  Step 5.
