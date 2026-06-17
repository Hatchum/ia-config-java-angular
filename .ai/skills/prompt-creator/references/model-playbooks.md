# Model Playbooks

Each model family rewards slightly different conventions. Read the section for
the target model in Step 3, then apply it while assembling (Step 4). When the
target is `agnostic`, use the **Cross-model default** at the bottom.

These are *prompting conventions and observed behaviors*, drawn from each
vendor's official prompt-engineering guidance. They are about how to phrase and
structure prompts — not API model IDs, pricing, or SDK details.

## Table of contents
- Claude (Anthropic)
- GPT (OpenAI)
- Gemini (Google)
- Cross-model default (`agnostic`)
- Quick comparison

---

## Claude (Anthropic)

**Delimiters:** XML tags are Claude's native structuring tool. Wrap each content
type in its own descriptive tag: `<instructions>`, `<context>`, `<examples>`,
`<example>`, `<input>`, `<document>`. Nest when there's a hierarchy
(`<documents><document index="1">…`).

**Role:** Put the role in the **system prompt** when one is available; otherwise
the first line of the prompt. One sentence is enough to shift tone.

**Reasoning:** Ask Claude to think. For tasks that benefit, add "Think step by
step" or instruct it to work through `<thinking>` tags before the answer. With
few-shot examples, show the reasoning inside `<thinking>` tags so Claude mirrors
the pattern. Prefer general guidance ("think thoroughly about X") over a rigid
hand-written step list — Claude's own reasoning often beats a prescribed one.

**Examples:** 3–5, each in an `<example>` tag, grouped in `<examples>`. Relevant
and diverse.

**Long context:** Place long documents/data **at the top**, with the query and
instructions **after** them (measurably better, up to ~30% on multi-doc tasks).
For long-document tasks, ask Claude to first pull relevant quotes into `<quotes>`
tags, then answer from them.

**Output control:** Say what to do, not what to avoid. Use XML tags as format
indicators ("write the summary in `<summary>` tags"). For machine-readable
output, ask for the structure directly or use structured output.

**Do NOT use prefill.** Last-turn assistant prefill is unsupported on current
Claude models. To force a format, instruct it directly or use structured output;
to skip preambles, say "Respond directly, without preamble."

**Avoid over-prompting.** Current Claude models follow instructions well and can
*over*-trigger on forceful language. Prefer "Use this tool when…" over "CRITICAL:
you MUST…". Don't pile on "always/never" — explain the reason instead.

---

## GPT (OpenAI)

**Structure:** Use Markdown headers in roughly this order — adapt to the task:
```
# Role and Objective
# Instructions
## <sub-category of instructions>
# Reasoning Steps
# Output Format
# Examples
# Context
```

**Instruction literalness:** GPT-4.x-class models follow instructions
*literally*. Two consequences:
- Avoid conflicting instructions; if two rules tension, the model tends to favor
  the one **later** in the prompt — so place the most important instructions near
  the end.
- Be explicit. Don't rely on the model to infer an unstated preference.

**Delimiters (ranked for large contexts):** Markdown first (clean, token-cheap),
then XML (precise, good for wrapping + metadata), then JSON (verbose, escaping
overhead). For document collections, XML or an `ID | TITLE | CONTENT` table beat
JSON.

**Examples:** Demonstrate important behaviors in `# Examples` *and* restate the
rule in `# Instructions` — varied examples plus explicit rules generalize best.

**Agentic prompts** (the prompt drives a tool-using loop): add the three system
reminders that materially lift agent performance —
- *Persistence:* "Keep going until the user's query is completely resolved before
  ending your turn."
- *Tool-calling:* "If unsure about file content or codebase structure, use your
  tools to read and gather the relevant information — do not guess or make
  things up."
- *Planning:* "Plan extensively before each function call, and reflect on the
  outcomes of previous calls."
- Make tool calls *conditional* ("if you need X, call …") so the model doesn't
  hallucinate calls; instruct variation so sample phrases don't get parroted.

**Avoid incentive theatrics:** all-caps, "I'll tip you", threats — unnecessary
with modern models.

---

## Gemini (Google)

**Structure:** Design with simplicity — concise, clear sections; cut anything
that doesn't earn its place. Clear headers are enough; no special tag dialect
required.

**Instructions over constraints:** Phrase as positive directions ("Respond in a
professional tone, focus on the three top risks") rather than stacks of
prohibitions. Google finds positive instructions more effective and less
brittle.

**Variables:** Use variables for dynamic values to keep prompts reusable.

**Few-shot:** Provide examples — Google calls this the most impactful single
practice. For classification, **mix up the class order** across examples so the
model doesn't overfit to ordering.

**Structured output:** For extraction/classification, request **JSON**. It forces
structure, limits hallucination, and is parseable. Define the schema.

**Config (Gemini exposes sampling controls — suggest starting points):**
| Task type | Temperature | Top-P | Top-K |
|-----------|-------------|-------|-------|
| Balanced / general | 0.2 | 0.95 | 30 |
| Factual / deterministic | 0.1 | 0.9 | 20 |
| Creative | 0.9 | 0.99 | 40 |
| Single correct answer (math, classification) | 0 | — | — |

Surface a config suggestion in the "Recommended config" section of the output
when the target is Gemini (or any API where the user controls sampling).

---

## Cross-model default (`agnostic`)

When no target model is given, optimize for portability:
- **Use XML-tagged sections.** All three families parse XML cleanly, so it's the
  safest universal structure: `<role>`, `<context>`, `<instructions>`,
  `<examples>`, `<output_format>`, `<input>`.
- Keep reasoning guidance general ("think step by step before answering").
- Use `{{double_brackets}}` variables.
- Avoid vendor-specific features (no prefill, no Gemini sampling assumptions, no
  OpenAI-only agent reminders unless the prompt is explicitly agentic).
- Mention in the design notes that the prompt is portable and how to specialize
  it (e.g. "switch tags to Markdown headers for pure GPT use").

---

## Quick comparison

| | Claude | GPT | Gemini |
|---|--------|-----|--------|
| Primary delimiter | XML tags | Markdown headers | Clear headers |
| Role goes in | System prompt | `# Role and Objective` | System/role prompt |
| Reasoning | "Think" / `<thinking>` | `# Reasoning Steps` | Chain-of-thought |
| Key quirk | Don't prefill; don't over-prompt | Literal — important rules last | Positive instructions; JSON output |
| Exposes sampling config | Via effort/API | Via API | Yes (temp/top-p/top-k) |
