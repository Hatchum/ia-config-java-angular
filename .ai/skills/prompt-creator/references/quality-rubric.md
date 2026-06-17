# The 10-Point Quality Rubric

The bar a generated prompt must clear. Each mark is the intersection of what
Anthropic, OpenAI, and Google independently recommend — when all three converge
on a practice, it is load-bearing, not stylistic.

Use this file two ways:
- **While building** (SKILL.md Step 4): aim for every mark.
- **While scoring** (SKILL.md Step 5): find the weakest mark and fix it.

A mark may be *intentionally skipped* when the task makes it irrelevant (e.g. a
trivial classifier needs no Context block). Skipping is a deliberate call you
note in the design notes — not an oversight.

## Table of contents
1. Role & objective
2. Crystal-clear task
3. Context & motivation
4. Clean structure & delimiters
5. Reasoning guidance
6. Concrete examples
7. Explicit output contract
8. Reusable variables
9. Positive framing & guardrails
10. Self-verification

---

## 1. Role & objective
**What it is:** The prompt opens by assigning an expert identity and stating a
one-line mission. Role-setting focuses the model's tone, vocabulary, and
priorities; even a single sentence measurably shifts output quality.

**Sources:** Anthropic ("Give Claude a role"), Google (role prompting), OpenAI
(Role & Objective is the first section of its recommended structure).

- ✅ `You are a senior security analyst. Your task is to triage CVE reports into
  severity tiers with a one-line justification each.`
- ❌ `Triage these CVEs.` (no persona, vague mission)

## 2. Crystal-clear task
**What it is:** The instruction is specific and unambiguous. The test, from
Anthropic, is the **golden rule of clear prompting**: *show the prompt to a
colleague with minimal context; if they'd be confused, the model will be too.*
Be explicit about scope; if you want "above and beyond" effort, ask for it.

**Sources:** Anthropic (be clear and direct), OpenAI (write clear instructions /
be explicit, GPT follows instructions literally), Google (be specific about
output).

- ✅ `Summarize the article in exactly 3 bullet points, each ≤ 20 words, focused
  on financial impact.`
- ❌ `Give me a short summary.` (how short? focused on what?)

## 3. Context & motivation
**What it is:** The prompt supplies the background the model needs *and* the
*why* behind the instructions. Models generalize better from a stated reason
than from a bare rule — Anthropic's canonical example: "never use ellipses
*because the response is read aloud by a TTS engine*" outperforms "never use
ellipses."

**Sources:** Anthropic (add context to improve performance), Google (contextual
prompting), OpenAI (provide reference text / context section).

- ✅ `This goes to non-technical executives, so explain terms on first use.`
- ❌ Instructions with no audience, domain, or rationale.

## 4. Clean structure & delimiters
**What it is:** Distinct parts of the prompt (instructions, context, examples,
input) are visually separated with consistent delimiters so the model never
confuses data for instructions. Delimiter choice is model-dependent (see
`model-playbooks.md`): XML tags for Claude, Markdown headers for GPT, clear
structure for Gemini. XML is the safe cross-model default.

**Sources:** Anthropic (structure with XML tags), OpenAI (delimiters: Markdown >
XML > JSON), Google (design with simplicity / structured formats).

- ✅ Sections wrapped in `<instructions>`, `<context>`, `<examples>`, `<input>`.
- ❌ A single run-on paragraph mixing the task, the data, and three caveats.

## 5. Reasoning guidance
**What it is:** For any task with intermediate steps — analysis, classification,
math, multi-criteria judgment — the prompt tells the model to reason before
answering (chain of thought), or lays out an ordered process. This reliably
raises accuracy. For simple lookups, skip it: forced reasoning just adds latency.

**Sources:** Anthropic (let Claude think / chain of thought), Google (CoT,
step-back), OpenAI (reasoning steps; "give the model time to think").

- ✅ `First list the key claims, then weigh evidence for each, then conclude.`
- ✅ `Work through your analysis in <thinking> tags before giving the answer.`
- ❌ Demanding a verdict on a complex question with no room to reason.

## 6. Concrete examples
**What it is:** One to five few-shot examples of ideal input→output. Examples are
the single most reliable lever on format, tone, and structure. Make them
**relevant** (mirror the real case), **diverse** (cover edge cases; don't let the
model latch onto an accidental pattern), and **delimited** (each in its own tag).
Skip when no good example exists or the task is purely generative and open-ended.

**Sources:** Anthropic (use examples / multishot, 3–5, relevant+diverse+
structured), Google (provide examples — "the single best thing"), OpenAI (varied
examples; cite them in the rules too).

- ✅ Two `<example>` blocks showing a hard case and an easy case, each with the
  exact output shape expected.
- ❌ Zero examples for a nuanced formatting task; or three near-identical examples
  that teach a spurious pattern.

## 7. Explicit output contract
**What it is:** The prompt pins down exactly what comes back: format (prose /
JSON / table / single label), length, tone, and language. For machine-consumed
output, specify a schema and prefer structured output (JSON or tagged fields) to
suppress stray prose and hallucination. State what to do *instead of* what to
avoid ("respond in flowing prose" beats "don't use bullets").

For **orchestrated dev work** (this skill's primary use case), the output contract
is the `<handoff>` block defined in `dev-orchestration.md` — a parseable envelope
(status, summary, archetype payload, verification, next actions) the orchestrator
reads to route the result. Default to it for dev prompts; drop it only for
one-off, non-orchestrated prompts.

**Sources:** Anthropic (control response format; say what to do, not what not to
do), Google (experiment with output formats; JSON limits hallucination), OpenAI
(specify desired output format with examples).

- ✅ `Return JSON: {"severity": "<low|med|high>", "reason": "<≤15 words>"}. No
  prose outside the JSON.`
- ❌ `Format it nicely.`

## 8. Reusable variables
**What it is:** Every dynamic value is a `{{placeholder}}`, so the prompt is a
reusable template rather than a one-off. Long inputs (documents, transcripts) go
**near the top**, above the instructions and query — Anthropic measures up to a
30% quality gain from placing the query after long context.

**Sources:** Anthropic (prompt templates & variables; long-context placement),
Google (use variables in prompts).

- ✅ `<document>{{ARTICLE_TEXT}}</document>` near the top; `{{TARGET_LANGUAGE}}`
  where used.
- ❌ A specific article pasted inline with no variable — unusable for the next
  input.

## 9. Positive framing & guardrails
**What it is:** Instructions tell the model what to do (positive direction
outperforms prohibition), and the prompt anticipates the messy real world:
edge cases, missing data, and a defined "when unsure" behavior (ask? flag?
return null?). For agents, this includes when to stop and when to act.

**Sources:** Google (instructions over constraints), Anthropic (what to do vs.
what not to do; balancing autonomy), OpenAI (handle edge cases; conditional
language so agents don't hallucinate tool calls).

- ✅ `If the text lacks a clear date, return "unknown" rather than guessing.`
- ❌ A prompt that assumes every input is well-formed and says nothing about
  failure modes.

## 10. Self-verification
**What it is:** The prompt asks the model to check its own output against stated
criteria before finishing. This catches errors cheaply, especially for code,
math, and structured extraction.

**Sources:** Anthropic (ask Claude to self-check / verify against test criteria),
Google (self-consistency; document & evaluate), OpenAI (iterate and reflect; for
agents, reflect on outcomes).

- ✅ `Before returning, verify the JSON parses and every required field is
  present; if not, fix it.`
- ❌ No checkpoint — the first draft is the final answer.

---

## Scoring shorthand

When self-scoring, give each mark a quick pass/fail and a one-line reason. A
prompt is ready when every applicable mark passes. Marks 1–4 and 7 are nearly
always applicable; 5, 6, 9, 10 depend on task complexity; 8 applies whenever the
prompt will be reused with different inputs.
