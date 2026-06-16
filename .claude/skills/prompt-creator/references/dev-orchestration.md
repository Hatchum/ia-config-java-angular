# Dev Orchestration

The primary use case: prompts that run under a **software-development orchestrator
agent**. This file defines what those prompts need beyond the generic rubric —
the parseable output contract, the per-archetype anatomy, and stack conventions.

Read this in Step 4 when the task is dev work.

## Table of contents
- The `<handoff>` output contract
- Task archetypes (planning / feature / bug-fix / review-refactor)
- Stack notes (MQL5 / Java / Angular)
- Worked example A — Java/Spring bug-fix sub-agent (Claude)
- Worked example B — MQL5 feature sub-agent (agnostic)

---

## The `<handoff>` output contract

An orchestrator routes work by **parsing** each agent's result, so the generated
prompt must make the target agent end its turn with a single, well-formed
`<handoff>` block. The agent may reason and use tools freely before it; the
handoff is the last thing it emits.

XML is the contract format: it parses cleanly across Claude, GPT, and Gemini, and
tolerates free text inside fields. Tell the agent to emit **exactly one**
`<handoff>` and nothing after it.

### Envelope (always present)
```xml
<handoff>
  <status>completed | blocked | needs_clarification | in_progress</status>
  <summary>One sentence, plain English: what was done or why it stopped.</summary>
  <confidence>high | medium | low</confidence>
  <next_actions>
    <action>What the orchestrator (or next agent) should do next.</action>
  </next_actions>
</handoff>
```

### Archetype payload (add the one that fits)
```xml
  <!-- planning -->
  <plan>
    <task id="1" depends_on="">Short title — what to do.
      <acceptance>Observable done-condition.</acceptance>
    </task>
    <task id="2" depends_on="1">…</task>
  </plan>

  <!-- feature / bug-fix / refactor: files touched -->
  <changes>
    <change path="src/main/java/.../OrderService.java" action="modified">
      One line on what changed and why.
    </change>
  </changes>

  <!-- bug-fix: add the root cause, not just the patch -->
  <diagnosis>
    <root_cause>The actual cause, evidenced from the code/trace.</root_cause>
  </diagnosis>

  <!-- review/refactor: findings by severity -->
  <findings>
    <finding severity="high|medium|low" path="...">Issue + suggested fix.</finding>
  </findings>
```

### Verification (whenever code changed)
```xml
  <verification>
    <command>mvn -q test</command>
    <result>pass | fail | not_run</result>
  </verification>
```

### Conditional fields
```xml
  <blockers><blocker>Why work cannot proceed.</blocker></blockers>            <!-- status=blocked -->
  <open_questions><question>What you need answered.</question></open_questions> <!-- status=needs_clarification -->
```

**Rules to bake into the generated prompt:**
- Emit exactly one `<handoff>`, as the final output, nothing after it.
- `status` drives orchestration: use `blocked` (with `<blockers>`) when you can't
  proceed, `needs_clarification` (with `<open_questions>`) when requirements are
  ambiguous — do **not** guess past a real ambiguity.
- Include `<verification>` with the real command and its actual result when you
  changed code. Never report `pass` you didn't observe.
- Keep `<summary>` to one sentence; detail goes in the payload fields.

---

## Task archetypes

Each archetype has a required shape. Build the `[INSTRUCTIONS]` and the handoff
payload around it.

### planning
**Goal:** turn a feature/requirement into an executable plan — no code changes.
**Instructions must cover:** restate the scope in one line; decompose into small,
ordered tasks with explicit `depends_on`; give each task an observable acceptance
criterion; surface risks, unknowns, and affected modules (consult `ARCHITECTURE.md`).
**Handoff:** `<plan>`; `status=needs_clarification` with `<open_questions>` if the
requirement is ambiguous. No `<changes>`/`<verification>`.

### feature
**Goal:** implement a change that satisfies a spec.
**Instructions must cover:** locate the integration points first; implement the
**minimal** change that follows existing conventions (don't over-engineer); add or
update tests; run the build and tests; clean up scratch files.
**Handoff:** `<changes>` + `<verification>`.

### bug-fix
**Goal:** fix the actual defect, not the symptom.
**Instructions must cover:** reproduce first (or state you couldn't and why);
find the **root cause** before touching code; apply the smallest correct fix; add
a regression test that fails before and passes after; run the suite.
**Handoff:** `<diagnosis>` + `<changes>` + `<verification>`; `status=blocked` if you
cannot reproduce or the repro is insufficient.

### review/refactor
**Goal:** improve quality without changing behavior.
**Instructions must cover:** assess against correctness, readability, performance,
security; list findings by severity; if applying changes, keep them behavior-
preserving and re-run tests to prove it.
**Handoff:** `<findings>` (+ `<changes>` + `<verification>` if you applied fixes).

---

## Stack notes

How to phrase the role, conventions, and **verification** per stack. This repo's
canonical build/test entry points are `scripts\build.*` and `scripts\test.*`
(see CLAUDE.md); prefer them in the prompt's verification step.

### mql5 (trading bots)
- **Role:** "expert MQL5 Expert-Advisor / indicator developer".
- **Conventions:** event handlers `OnInit` / `OnTick` / `OnTimer` / `OnDeinit`;
  own orders via a **magic number**; normalize lots and prices
  (`NormalizeDouble`, respect `SYMBOL_VOLUME_STEP` / `_Digits`); check
  `GetLastError`; guard against the trade context being busy; **no look-ahead
  bias** (don't read the still-forming bar as if closed).
- **Verification:** there is no standard unit-test framework. Define verification
  as: "compiles cleanly in MetaEditor with zero errors/warnings, then runs in the
  **Strategy Tester** on `<symbol>` `<timeframe>` over `<date range>` with no
  critical runtime errors." Put those Strategy Tester parameters in the handoff
  `<verification><command>`.

### java (Java / Spring, Maven reactor)
- **Role:** "senior Java/Spring Boot engineer".
- **Conventions:** follow `.claude/rules/java-coding-rules.md` and the layering in
  `ARCHITECTURE.md`; tests in JUnit 5 + AssertJ + Mockito (see the `test-quality`
  skill); don't break module dependency direction.
- **Verification:** `scripts\test.cmd` (or `mvn -q test`); build green via
  `scripts\build.cmd`. "Done" = both green.

### angular
- **Role:** "senior Angular engineer".
- **Conventions:** follow `.claude/rules/angular-coding-rules.md` and the relevant
  `<angular-module>/CLAUDE.md`; standalone components/services; respect smart/dumb
  component boundaries.
- **Verification:** `ng test` (Karma/Jasmine) and `ng build` green, or the repo's
  frontend scripts if defined; lint clean.

---

## Worked example A — Java/Spring bug-fix sub-agent (Claude)

**User parameters:** "Sub-agent prompt for Claude that fixes a bug in our Spring
service. It'll get the failing test name and a stack trace." (Stack `java`,
archetype `bug-fix`, model `claude` — rest inferred.)

```text
<role>
You are a senior Java/Spring Boot engineer working as a sub-agent under an
orchestrator. Your task is to find and fix the root cause of a single failing
bug, then hand the result back in a machine-parseable form.
</role>

<context>
You operate in a Maven multi-module repository. Follow the coding rules in
.claude/rules/java-coding-rules.md and the layering in ARCHITECTURE.md. Tests use
JUnit 5 + AssertJ + Mockito. The orchestrator gates on a green build, which is why
verification is mandatory before you report success.
</context>

<inputs>
<failing_test>{{FAILING_TEST}}</failing_test>
<stack_trace>{{STACK_TRACE}}</stack_trace>
</inputs>

<instructions>
1. Reproduce the failure by running the failing test (scripts\test.cmd or
   `mvn -q -Dtest={{FAILING_TEST}} test`). If you cannot reproduce it, stop and
   report status=blocked with what you observed.
2. Read the implicated code before changing anything — never speculate about a
   file you have not opened. Identify the true root cause, not the symptom.
3. Apply the smallest correct fix that follows existing conventions. Do not
   refactor unrelated code or add abstractions that were not requested.
4. Add or adjust a regression test that fails before your fix and passes after.
5. Run the full module test suite to confirm green and no new failures.
</instructions>

<reasoning>
Work through the diagnosis in <thinking> tags before editing: trace the failure
from the stack trace to the responsible method, and state the root cause.
</reasoning>

<output_format>
End your turn with exactly one <handoff> block and nothing after it:
<handoff>
  <status>completed | blocked | needs_clarification</status>
  <summary>One sentence.</summary>
  <confidence>high | medium | low</confidence>
  <diagnosis><root_cause>...</root_cause></diagnosis>
  <changes>
    <change path="..." action="modified">what and why</change>
  </changes>
  <verification><command>scripts\test.cmd</command><result>pass | fail</result></verification>
  <next_actions><action>...</action></next_actions>
  <!-- include <blockers> only if status=blocked -->
</handoff>
</output_format>

Before emitting the handoff, confirm the suite is green and the regression test
actually fails without your fix; if not, set status accordingly and explain.
```

**Why it scores 10/10:** role+objective ✓; clear task ✓; context (rules, layering,
why verify) ✓; XML structure ✓; `<thinking>` root-cause reasoning ✓; (examples
intentionally skipped — a stack trace is the concrete input) ✓ output contract =
handoff ✓; `{{FAILING_TEST}}`/`{{STACK_TRACE}}` variables ✓; guardrails (can't
reproduce → blocked; minimal fix; no speculation) ✓; verification before reporting ✓.

---

## Worked example B — MQL5 feature sub-agent (agnostic)

**User parameters:** "Prompt to add a trailing stop to our MQL5 EA." (Stack
`mql5`, archetype `feature`, model unspecified → agnostic/XML.)

```text
<role>
You are an expert MQL5 Expert-Advisor developer working as a sub-agent under an
orchestrator. Your task is to implement one feature in an existing EA and hand the
result back in a machine-parseable form.
</role>

<context>
The EA manages its own orders by magic number. Prices and lots must be normalized
to the symbol's digits and volume step. There is no unit-test framework for MQL5,
so verification means a clean MetaEditor compile plus a Strategy Tester run — this
is how the orchestrator confirms the change is safe.
</context>

<feature_request>
{{FEATURE_REQUEST}}
</feature_request>

<instructions>
1. Locate where the EA opens and manages positions before adding anything.
2. Implement the feature as a minimal, self-contained addition to the order-
   management logic. Trail only this EA's positions (match the magic number).
3. Normalize every price with NormalizeDouble to _Digits; respect stop-level
   constraints. Modify positions via the standard trade calls and check the
   result; on failure, read GetLastError and do not retry blindly.
4. Avoid look-ahead bias: act on completed bars / current tick data only.
5. Confirm a clean compile, then describe a Strategy Tester run to validate it.
</instructions>

<reasoning>
Think step by step before coding: identify the exact insertion point in the order
loop and the conditions under which the stop should move.
</reasoning>

<output_format>
End your turn with exactly one <handoff> block and nothing after it:
<handoff>
  <status>completed | blocked | needs_clarification</status>
  <summary>One sentence.</summary>
  <confidence>high | medium | low</confidence>
  <changes>
    <change path="Experts/MyEA.mq5" action="modified">what and why</change>
  </changes>
  <verification>
    <command>Compile in MetaEditor; Strategy Tester EURUSD H1 2023.01-2023.06</command>
    <result>pass | fail | not_run</result>
  </verification>
  <next_actions><action>...</action></next_actions>
</handoff>
</output_format>

Before emitting the handoff, confirm the code compiles with zero errors and that
the trailing logic only touches positions matching this EA's magic number.
```

**Why it scores 10/10:** role+objective ✓; clear task ✓; context (magic number,
normalization, why verify) ✓; XML structure ✓; step-by-step reasoning ✓; (examples
skipped — feature request is the input) ✓ handoff contract ✓; `{{FEATURE_REQUEST}}`
variable ✓; stack-specific guardrails (normalization, magic number, no look-ahead,
GetLastError) ✓; compile + Strategy Tester verification ✓.
