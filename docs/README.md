# Documentation — index

Ce dossier est organisé en trois familles selon l'intention.

## `guide/` — opérer le kit (spécifique à ce dépôt)

| Fichier | Pour |
|---|---|
| [`architecture-biagent.md`](guide/architecture-biagent.md) | **Architecture bi-agent** Claude ↔ Codex : une source, deux projections. Le piège « Rules », le layout `.ai/`, le générateur, et l'**état d'avancement** (§11). |
| [`install.md`](guide/install.md) | Installer le kit dans un monorepo Java + Angular existant (placeholders, shell, linters). |
| [`config.md`](guide/config.md) | Référence `.claude/` : permissions, hooks, subagents, logs. |
| [`mcp.md`](guide/mcp.md) | Serveurs MCP (GitLab/GitHub/Duo, Context7, Exa) + décision CLI `ctx7`. |
| [`roadmap.md`](guide/roadmap.md) | Plan d'implémentation et backlog « à créer ». |

## `reference/` — manuel Claude Code (connaissance générique, vérifiée)

| Fichier | Sujet |
|---|---|
| [`claude-md.md`](reference/claude-md.md) | Fondation `CLAUDE.md`, hiérarchie, imports `@path`. |
| [`rules.md`](reference/rules.md) | `.claude/rules/` path-scopées. |
| [`skills.md`](reference/skills.md) | Skills : frontmatter, invocation, cycle de vie. |
| [`subagents.md`](reference/subagents.md) | Subagents : frontmatter, mémoire, invocation. |
| [`workflows.md`](reference/workflows.md) | EPCT, signal pass/fail, workflow debug. |
| [`models.md`](reference/models.md) | Modèles (opus/sonnet/haiku/fable), `effort`. |
| [`hooks.md`](reference/hooks.md) | Hooks déterministes : événements, codes de sortie. |
| [`lsp.md`](reference/lsp.md) | Code intelligence par plugin LSP. |
| [`context-management.md`](reference/context-management.md) | Contexte, sessions, compaction, anti-patterns. |
| [`automation.md`](reference/automation.md) | Mode non-interactif, fan-out, `/loop`, `/schedule`. |
| [`agent-system-logs.md`](reference/agent-system-logs.md) | Debug log + OpenTelemetry (attribution par subagent). |

## `research/` — explorations

| Fichier | Sujet |
|---|---|
| [`rag.md`](research/rag.md) | RAG vs recherche agentique — reco pour ce projet. |
| [`prompt-drafts.md`](research/prompt-drafts.md) | Brouillons de méta-prompts et templates de skills. |
| [`subagent-creator-research.md`](research/subagent-creator-research.md) · [`subagent-creator-prompt.md`](research/subagent-creator-prompt.md) | Provenance du skill `subagent-creator` (artefacts internes, non copiés en cible). |

---

## Lecture par objectif du projet

- **Config bi-agent fonctionnelle (Anthropic / OpenAI)** → `guide/architecture-biagent.md`,
  `install.md`, `config.md`, `mcp.md` + `reference/{hooks,lsp,agent-system-logs}.md`.
- **Structure agentique pour le dev/correctif Java + Angular** →
  `reference/{skills,subagents,workflows,models,rules,claude-md}.md` + `guide/roadmap.md`.
