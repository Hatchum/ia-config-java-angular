# Templates (Skeletons)

Fill-in skeletons per model family. Copy one, delete sections the task doesn't
need, and replace the `<…>` guidance and `{{VARIABLES}}`.

For the **primary use case** (orchestrated dev work — planning, feature, bug-fix,
review), the `OUTPUT FORMAT` section should be the `<handoff>` contract, and the
instructions should follow the archetype shape. Full dev worked examples (Java
bug-fix, MQL5 feature) and the handoff spec live in `dev-orchestration.md` — read
it alongside these skeletons.

## Table of contents
- Skeleton: Claude / agnostic (XML)
- Skeleton: GPT (Markdown)
- Skeleton: Gemini

---

## Skeleton: Claude / agnostic (XML)

```text
<role>
You are <expert role for the stack>. Your task is to <one-line objective>.
</role>

<context>
<code/trace/requirements, conventions to follow, and why this matters>
</context>

<instructions>
1. <first step — for dev, follow the archetype shape from dev-orchestration.md>
2. <next step>
3. <handle the edge cases: missing repro, ambiguous spec, failing build>
</instructions>

<reasoning>
Think step by step inside <thinking> tags before you act:
<what to analyze first, then how to decide>.
</reasoning>

<examples>   <!-- optional; skip when the input itself is the concrete spec -->
<example>
Input: <representative input>
Output: <exact ideal output>
</example>
</examples>

<output_format>
<the <handoff> contract for orchestrated dev work (see dev-orchestration.md),
or an explicit schema/format for other tasks>
</output_format>

<input>
<longform code/data near the top if very large>
{{INPUT_VARIABLE}}
</input>

Before finishing, verify <criteria / run the build>; then emit the handoff.
```

---

## Skeleton: GPT (Markdown)

```text
# Role and Objective
You are <expert role>. Your goal is to <one-line objective>.

# Agent reminders   <!-- include for agentic/orchestrated prompts -->
- Persistence: keep going until the task is fully resolved before yielding.
- Tool use: if unsure about code or data, use tools to gather it — do not guess.
- Planning: plan before each tool call and reflect on the result after.

# Instructions
- <high-level rule>
## <Sub-category, e.g. "Handling a failing build">
- <specific rule>

# Reasoning Steps
1. <step>
2. <step>

# Output Format
<the <handoff> contract (see dev-orchestration.md) or an explicit schema/format>

# Examples
## Example 1
Input: <input>
Output: <ideal output>

# Context
<background, conventions, source material>
{{CONTEXT_VARIABLE}}

# Most important
<restate the one or two rules that matter most — GPT weights later instructions>
```

---

## Skeleton: Gemini

```text
You are <expert role>. <One-line objective>.

Instructions:
- <positive instruction — say what to do, not what to avoid>

Steps:
1. <step>
2. <step>

Output: <the <handoff> contract, or return JSON matching this schema>:
{ "<field>": "<type/constraint>" }

Examples:
- Input: <input> → Output: <output>

Input to process:
{{INPUT_VARIABLE}}

Verify the output before returning it.
```
Suggested config: temperature `<per task — see model-playbooks.md>`.
