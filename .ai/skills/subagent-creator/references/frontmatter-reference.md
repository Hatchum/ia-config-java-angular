# Frontmatter reference — Claude Code subagents

Full reference for the YAML frontmatter of a Claude Code subagent file
(`.claude/agents/<name>.md`). The skill's core workflow covers the common
parameters; reach for this file when you need a field beyond them.

> Source of truth: official Anthropic docs (see § Sources). Distilled in the
> repo's `docs/subagent-creator-research.md`.

## Anatomy

A subagent is a Markdown file: **YAML frontmatter** (config) + **Markdown body**
(the system prompt). The subagent receives only this system prompt plus basic
environment (working dir, CLAUDE.md, git status) — not Claude Code's full system
prompt. Claude delegates to it when a task matches its `description`; it runs in an
isolated context window and returns only a summary.

## All supported frontmatter fields

Only `name` and `description` are required.

| Field | Required | Description | Values / default |
|-------|----------|-------------|------------------|
| `name` | **Yes** | Unique identifier; the invocation handle | lowercase + hyphens |
| `description` | **Yes** | When Claude should delegate to this subagent | clear sentence; add "use proactively" to push delegation |
| `tools` | No | Allowlist of tools the subagent may use | inherits all if omitted |
| `disallowedTools` | No | Denylist, applied **before** `tools` | — |
| `model` | No | Model the subagent runs on | `sonnet` · `opus` · `haiku` · `fable` · full ID (`claude-opus-4-8`) · `inherit`. **Default `inherit`** |
| `permissionMode` | No | Permission handling | `default` · `acceptEdits` · `auto` · `dontAsk` · `bypassPermissions` · `plan` |
| `maxTurns` | No | Max agentic turns before stopping | — |
| `skills` | No | Skills preloaded into context at startup (full content injected) | — |
| `mcpServers` | No | MCP servers scoped to this subagent | inline def or name reference |
| `hooks` | No | Lifecycle hooks (`PreToolUse`, `PostToolUse`, `Stop`) | — |
| `memory` | No | Persistent cross-session memory directory | `user` · `project` · `local` |
| `background` | No | Always run as a background task | default `false` |
| `effort` | No | Effort level while active | `low` … `max` |
| `isolation` | No | Run in a temporary git worktree | `worktree` |
| `color` | No | Display color in the task list/transcript | red/blue/green/yellow/purple/orange/pink/cyan |
| `initialPrompt` | No | Auto-submitted first turn when run as main agent (`--agent`) | — |

> Note: plugin subagents ignore `hooks`, `mcpServers`, and `permissionMode` for
> security reasons.

## Model resolution order

When a subagent runs, Claude Code resolves its model in this order:
1. `CLAUDE_CODE_SUBAGENT_MODEL` environment variable, if set
2. Per-invocation `model` parameter passed by Claude
3. The subagent definition's `model` frontmatter
4. The main conversation's model

So `model: inherit` (or omitting it) falls through to the main conversation.

## Scopes and locations (priority high → low)

| Location | Scope | How to create |
|----------|-------|---------------|
| Managed settings `.claude/agents/` | Organization-wide | Deployed by admins |
| `--agents` CLI flag (JSON) | Current session | Pass JSON at launch |
| `.claude/agents/` | Current project | Manual or `/agents` — **check into VCS to share** |
| `~/.claude/agents/` | All your projects | Manual or `/agents` |
| Plugin `agents/` directory | Where plugin enabled | Installed via plugin |

Identity comes only from the `name` field (not the filename or subfolder). Keep
`name` unique across the tree. Files edited on disk load on **session restart**;
files created through `/agents` load immediately.

## Tools not available to subagents

Even if listed in `tools`, these are unavailable because they depend on the main
UI/session: `AskUserQuestion`, `EnterPlanMode`, `ExitPlanMode` (unless
`permissionMode: plan`), `ScheduleWakeup`, `WaitForMcpServers`.

MCP patterns work in `tools`/`disallowedTools`: `mcp__<server>` or
`mcp__<server>__*` grant/remove a whole server; in `disallowedTools`, `mcp__*`
removes every MCP tool.

## Cross-provider design notes (OpenAI)

OpenAI's agent guidance corroborates the same shape: an agent = an LLM configured
with **instructions** (≈ the system-prompt body), **model**, **tools**, and
optional **handoffs** (delegating to specialist agents) and **guardrails**
(input/output validation — the analogue of restricting tools / `permissionMode`).
Best practices echo Anthropic's: give clear instructions, keep tool access scoped,
prefer structured/parseable output, and layer multiple guardrails rather than
relying on one.

## Sources

- Anthropic — Create custom subagents: https://code.claude.com/docs/en/sub-agents
- Anthropic — Agent SDK subagents: https://code.claude.com/docs/en/agent-sdk/subagents
- Anthropic — Plugins reference (agents): https://code.claude.com/docs/en/plugins-reference
- OpenAI — A practical guide to building agents: https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/
- OpenAI — Agents SDK (Agents): https://openai.github.io/openai-agents-python/agents/
- OpenAI — Agents SDK (Handoffs): https://openai.github.io/openai-agents-python/handoffs/
