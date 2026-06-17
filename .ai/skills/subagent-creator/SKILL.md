---
name: subagent-creator
description: >-
  Create high-quality Claude Code subagents — the Markdown agent files in
  .claude/agents/ that Claude delegates specialized tasks to. Use this skill
  whenever the user wants to create, design, scaffold, write, generate, or
  improve a subagent, custom agent, or specialized AI assistant for Claude Code,
  even when they don't say the word "subagent" (e.g. "make an agent that reviews
  my PRs", "I want a dedicated researcher agent", "set up a test-runner",
  "give me a security auditor agent"). The skill always settles the target LLM
  model (sonnet / opus / haiku / fable / inherit) plus name, trigger description,
  tools, and system prompt, then emits a ready-to-save agent file with valid YAML
  frontmatter and a focused system prompt, following official Anthropic and
  OpenAI agent-design best practices.
metadata:
  type: reference
---

# Subagent Creator

Turn a rough request ("I want an agent that reviews PRs") into a **ready-to-save
Claude Code subagent file**: valid YAML frontmatter + a focused system prompt that
Claude can delegate to.

A subagent runs in its **own context window**, with its **own system prompt**, a
**restricted tool set**, and its **own model** — it does a self-contained job and
returns only a summary. Claude decides to delegate based on the subagent's
`description`. So the three things that make a subagent good are: a **focused
scope**, a **specific description** (the delegation trigger), and a **deliberate
model + tool choice**. This skill makes each of those explicit instead of leaving
them to chance.

Domain reference (field table, advanced fields, sources) lives in
`references/frontmatter-reference.md` — read it when you need a field this skill's
parameter list doesn't cover.

## Workflow

### Step 1 — Collect the parameters

Map whatever the user gave you onto the set below. Infer everything you can from
the request; only stop to ask when a **required** value is genuinely ambiguous.

| Parameter | What it is | Required? | Maps to |
|-----------|-----------|-----------|---------|
| **name** | Unique identifier, kebab-case (e.g. `pr-reviewer`) | **Yes** | `name` |
| **description (trigger)** | *When* Claude should delegate to this agent | **Yes** | `description` |
| **model** | Which LLM the subagent runs on | **Yes** (confirm it) | `model` |
| **purpose + system prompt** | The agent's role, workflow, and output | **Yes** | Markdown body |
| **tools** | Least-privilege allowlist of tools | No — infer | `tools` |
| **disallowedTools** | Tools to remove from the inherited set | No | `disallowedTools` |
| **scope** | Project (`.claude/agents/`) or user (`~/.claude/agents/`) | No — default project | file location |
| **permissionMode** | `default` / `acceptEdits` / `plan` / … | No | `permissionMode` |
| **advanced** | `skills`, `memory`, `color`, `maxTurns`, `isolation`, `hooks` | No | same-named fields |

**Why `model` is always settled explicitly:** it is the single biggest lever on
cost and quality, and it silently defaults to `inherit` if you forget it. Don't
let it slip — pick it deliberately (Step 2) and tell the user what you chose.

### Step 2 — Choose the model deliberately

The `model` field accepts `sonnet`, `opus`, `haiku`, `fable`, a full model ID
(e.g. `claude-opus-4-8`), or `inherit` (use the main conversation's model;
this is the default if omitted). Recommend from the task, then confirm:

- **`haiku`** — fast and cheap. Read-only exploration, search, log/triage,
  high-volume work where you mostly want a summary back.
- **`sonnet`** — balanced capability/speed. Code review, analysis, most
  day-to-day specialist agents.
- **`opus`** — most capable. Hard reasoning, architecture, tricky debugging,
  high-stakes changes.
- **`inherit`** — match the main session; good when the agent should be as
  capable as whatever the user is currently running.

State your recommendation and the reason ("read-only researcher → haiku, to keep
it cheap"), and let the user override.

### Step 3 — Choose tools with least privilege

Subagents inherit every tool by default. That is rarely what you want: granting
only what the job needs improves safety and focus, and is an explicit Anthropic
best practice. Decide from the purpose:

- **Read-only agent** (reviewer, researcher, auditor): `Read, Grep, Glob` (+ `Bash`
  only if it must run commands like `git diff`). Never `Write`/`Edit`.
- **Agent that changes code** (fixer, refactorer): add `Edit`, `Write`, `Bash`.
- Prefer the `tools` allowlist; use `disallowedTools` only when "inherit all
  except a few" is genuinely cleaner.

`AskUserQuestion`, `EnterPlanMode`, `ExitPlanMode`, and `ScheduleWakeup` are not
available to subagents even if listed — don't add them.

### Step 4 — Write the system prompt (the body)

The body becomes the subagent's entire system prompt (it does **not** inherit
Claude Code's full system prompt). Follow the anatomy the official examples all
use — explain the role, then give a concrete procedure, then the output shape:

```
You are a <expert role>. <One-line mission.>

When invoked:
1. <first concrete step>
2. <next step>
3. <…>

<Domain checklist or key practices — what to look for / how to work.>

<Output format: how the agent should present its result back.>
```

Keep it focused on one job. A subagent that tries to do everything delegates
poorly and wastes context.

### Step 5 — Assemble and emit the agent file

Produce the complete file. `name` and `description` are the only required
frontmatter fields; include `model` and `tools` because we settled them
deliberately. Use this exact structure:

```markdown
---
name: <kebab-case-name>
description: <when Claude should delegate — specific; add "use proactively" to push delegation>
tools: <Tool1, Tool2>            # omit to inherit all
model: <sonnet | opus | haiku | fable | inherit>
---

<system prompt body from Step 4>
```

Tell the user **where to save it** — `.claude/agents/<name>.md` for the project
(check into version control to share) or `~/.claude/agents/<name>.md` for personal
use — and that a **session restart** is needed to load a file edited on disk
(files created via the `/agents` command load immediately).

### Step 6 — Self-check before delivering

Confirm:
1. **Scope is focused** — the agent does one thing well.
2. **Description is specific** — it says *when* to use the agent, not just what it
   is, so Claude can route to it (add "use proactively" if proactive delegation
   is wanted).
3. **Model is set deliberately** and the choice is justified to the user.
4. **Tools are least-privilege** — no `Write`/`Edit` on a read-only agent.
5. **Body follows the anatomy** — role → "when invoked" steps → checklist →
   output format.
6. **Frontmatter is valid** — `name` is kebab-case; `description` has no angle
   brackets.

## Output format (how you reply to the user)

````markdown
## Your subagent

```markdown
<the complete, ready-to-save agent file>
```

## Where to save it
`.claude/agents/<name>.md` (project) — restart the session to load it.

## Choices
- **Model:** <value> — <why>
- **Tools:** <list> — <why these / why restricted>
- **Assumptions:** <anything inferred, so the user can correct it>
````

## Principles

- **Focused beats broad.** One subagent, one job. Anthropic's first best practice.
- **The description is the trigger.** Claude delegates off the `description`; vague
  descriptions mean the agent never gets used. Be specific about *when*.
- **Least privilege.** Grant only the tools the job needs — safer and more focused.
- **Model is a cost/quality decision, not an afterthought.** Always settle it.
- **Explain inside the generated prompt.** Models follow a stated *reason* better
  than a bare MUST — write "run git diff first so you review only what changed",
  not just "ALWAYS run git diff".

## Reference files

- `references/frontmatter-reference.md` — the full frontmatter field table
  (all supported fields, model resolution order, scopes/locations), advanced
  fields, and the official Anthropic + OpenAI sources. Read when you need a field
  beyond the core parameter set.
