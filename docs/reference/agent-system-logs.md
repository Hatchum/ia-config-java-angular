# Agent System Logs — Claude Code

> Compiled and validated against the official Claude Code documentation
> (June 2026). Sources are listed at the bottom of this file.
>
> Goal: how to enable **system logs** when running Claude Code **agents /
> subagents** — both the local **debug log** and the **OpenTelemetry (OTel)**
> telemetry that carries per-agent attribution.

There are **two independent logging layers**. Pick the one that matches your need:

| Layer | Use when you want to… | Output |
|-------|-----------------------|--------|
| **Debug log** (local file) | Diagnose a single session locally: hook firing, MCP startup, settings resolution, subagent loading | A text file on disk |
| **OpenTelemetry** (telemetry) | Observe usage/cost/tool activity across sessions, with per-subagent attribution, exported to a backend | Metrics, log events, optional traces over OTLP |

---

## 1. Debug log (local, per-session)

The debug log records what happens inside a session: events processed, which
hook matchers were checked, MCP server stderr, settings resolution, and missing
or disabled skills/subagents.

### Enable it

Debug mode must be turned on first. Any of these works:

| Method | How |
|--------|-----|
| CLI flag | `claude --debug` |
| Scoped CLI flag | `claude --debug hooks` · `claude --debug mcp` (limits noise to one subsystem) |
| In-session | run `/debug` (optionally `/debug <issue>` to have Claude diagnose) |
| Environment | set `DEBUG` |

### Control where it goes and how verbose it is

| Environment variable | Effect | Values / default |
|----------------------|--------|------------------|
| `CLAUDE_CODE_DEBUG_LOGS_DIR` | Override the debug log file location. Requires debug mode enabled separately. | Default: `~/.claude/debug/<session-id>.txt` |
| `CLAUDE_CODE_DEBUG_LOG_LEVEL` | Minimum level written to the file | `verbose`, `debug` (default), `info`, `warn`, `error` |

> Set `CLAUDE_CODE_DEBUG_LOG_LEVEL=verbose` for high-volume diagnostics, or raise
> to `error` to reduce noise.

There is also a `--debug-file <path>` flag (useful to dump the log somewhere and
grep it, e.g. for "Remote settings" delivery issues).

### What it tells you about agents/subagents

- A missing or disabled skill referenced by an agent is **skipped and logged as a
  warning** to the debug log.
- `--debug hooks` records each event, which matchers were checked, and each
  hook's exit code and output — useful when a subagent's tool call should trigger
  a hook but doesn't.

### Windows / PowerShell example

```powershell
$env:CLAUDE_CODE_DEBUG_LOG_LEVEL = "verbose"
$env:CLAUDE_CODE_DEBUG_LOGS_DIR  = "C:\logs\claude"
claude --debug
```

### Related diagnostic commands (no logging needed)

These show *what actually loaded*, which is often the real question behind
"why is my agent misbehaving":

| Command | Shows |
|---------|-------|
| `/agents` | Configured subagents and their settings |
| `/context` | Everything in the context window (system prompt, memory, skills, MCP tools) |
| `/doctor` | Config diagnostics: invalid keys, schema errors |
| `/status` | Active settings sources (incl. managed settings) |

---

## 2. OpenTelemetry telemetry (export + per-agent attribution)

This is the layer that gives you **system-wide logs with subagent attribution**
(which agent issued a request, token/cost per agent, tool calls per agent).

### Minimum to enable

Telemetry is **off** until you both enable it and choose at least one exporter.

```bash
# 1. Enable telemetry (required)
export CLAUDE_CODE_ENABLE_TELEMETRY=1

# 2. Choose exporters (configure only what you need)
export OTEL_METRICS_EXPORTER=otlp   # otlp | prometheus | console | none
export OTEL_LOGS_EXPORTER=otlp      # otlp | console | none

# 3. Point at a collector
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc          # grpc | http/json | http/protobuf
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

# 4. Auth (if required)
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer your-token"
```

> **Quick local check, no collector needed:** set
> `OTEL_LOGS_EXPORTER=console` (and/or `OTEL_METRICS_EXPORTER=console`) to print
> events straight to the terminal.

### PowerShell (Windows) equivalent

```powershell
$env:CLAUDE_CODE_ENABLE_TELEMETRY = "1"
$env:OTEL_LOGS_EXPORTER           = "console"   # or otlp
$env:OTEL_METRICS_EXPORTER        = "console"
claude
```

### Core configuration variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | Master switch (required) | off |
| `OTEL_METRICS_EXPORTER` | Metrics exporter(s), comma-separated. `none` to disable | — |
| `OTEL_LOGS_EXPORTER` | Logs/events exporter(s), comma-separated. `none` to disable | — |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | Protocol for all signals | — |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Collector endpoint for all signals | — |
| `OTEL_EXPORTER_OTLP_HEADERS` | Auth headers | — |
| `OTEL_METRIC_EXPORT_INTERVAL` | Metrics export interval (ms) | `60000` |
| `OTEL_LOGS_EXPORT_INTERVAL` | Logs export interval (ms) | `5000` |

Per-signal overrides exist too (`OTEL_EXPORTER_OTLP_LOGS_ENDPOINT`,
`OTEL_EXPORTER_OTLP_METRICS_PROTOCOL`, etc.) when metrics and logs go to
different backends.

### Logging content gates (off by default)

By default, prompt/tool content is **redacted**. Enable explicitly:

| Variable | Reveals |
|----------|---------|
| `OTEL_LOG_USER_PROMPTS=1` | User prompt content |
| `OTEL_LOG_TOOL_DETAILS=1` | Tool parameters/inputs (Bash commands, MCP/tool/skill names, **`subagent_type`** for the Agent tool) |
| `OTEL_LOG_TOOL_CONTENT=1` | Tool input/output content in span events (requires tracing; truncated at 60 KB) |
| `OTEL_LOG_RAW_API_BODIES=1` | Full Messages API request/response JSON (implies the three gates above; `file:<dir>` for untruncated bodies on disk) |

> These can expose sensitive data. Enable deliberately, and prefer managed
> settings for org-wide control.

### Per-agent attribution (the part that matters for agents)

Claude Code tags telemetry with which agent did what:

- **Log events** (`api_request`, `tool_result`, `cost`/`token` metrics, …) carry:
  - `query_source` — `"main"`, `"subagent"`, or `"auxiliary"` (or a subagent
    name on events).
  - `agent.name` — the subagent **type** that issued the request. Built-in and
    official-marketplace agent names appear verbatim; other user-defined names
    collapse to `"custom"`.
- **Tool events / spans** carry `subagent_type` (gated by `OTEL_LOG_TOOL_DETAILS`).
- **Traces (beta)** nest a subagent's spans **under the parent's
  `claude_code.tool` span**, so a full prompt → subagent → API/tool chain shows
  as one trace. Span attributes include `agent_id` and `parent_agent_id`.

To filter telemetry to "everything a subagent did", group by `query_source`
/ `agent.name` (events & metrics) or by `agent_id` (traces).

### Traces (beta) — optional, for the full agent call tree

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1     # required for spans
export OTEL_TRACES_EXPORTER=otlp                 # otlp | console | none
```

Span hierarchy (subagent spans nest under the parent's tool span):

```text
claude_code.interaction
├── claude_code.llm_request
├── claude_code.hook                 (requires detailed beta tracing)
└── claude_code.tool
    ├── claude_code.tool.blocked_on_user
    ├── claude_code.tool.execution
    └── (Agent tool) subagent claude_code.llm_request / claude_code.tool spans
```

### Org-wide config via managed settings

Set the same variables in the managed `settings.json` `env` block so every user
gets them and **cannot override** (high precedence):

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://collector.example.com:4317",
    "OTEL_EXPORTER_OTLP_HEADERS": "Authorization=Bearer example-token"
  }
}
```

> **Note:** Claude Code does **not** pass `OTEL_*` variables to subprocesses it
> spawns (Bash tool, hooks, MCP servers, language servers). Set those directly in
> the command if a spawned program needs to export its own telemetry.

---

## 3. Which one do I want?

- **"Why did my subagent ignore a hook / not load a skill?"** → Debug log
  (`claude --debug hooks`), plus `/agents`, `/doctor`.
- **"Track cost/tokens/tool usage per subagent across the team."** →
  OpenTelemetry metrics + logs, grouped by `query_source` / `agent.name`.
- **"See the full agent → subagent → API call tree for one prompt."** →
  OpenTelemetry traces (beta) with `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1`.

---

## Sources

- [Monitoring (OpenTelemetry) — Claude Code Docs](https://code.claude.com/docs/en/monitoring-usage)
- [Environment variables — Claude Code Docs](https://code.claude.com/docs/en/env-vars)
- [Debug your configuration — Claude Code Docs](https://code.claude.com/docs/en/debug-your-config)
- [Create custom subagents — Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- [Observability with OpenTelemetry (Agent SDK) — Claude Code Docs](https://code.claude.com/docs/en/agent-sdk/observability)
