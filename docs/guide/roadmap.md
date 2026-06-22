# Roadmap d'implémentation

> Plan d'optimisation de la configuration Claude Code. Extrait de l'ancien
> monolithe `docs/TASK.md` (désormais éclaté en fiches de référence — voir
> [`docs/reference/`](../reference/)).

## Deux suivis distincts

| Suivi | Où |
|---|---|
| **État d'avancement de la config bi-agent** (Claude ↔ Codex : instructions, skills, permissions, hooks, générateur) | [`architecture-biagent.md` §11](architecture-biagent.md) (✅ fait / ❌ reste à faire) |
| **Backlog d'optimisation Claude Code** (skills, subagents, hooks à créer) | ci-dessous + sections « à créer » des fiches de [`reference/`](../reference/) |

## Backlog « à créer » (consolidé)

- **Skills** → cf. [`reference/skills.md`](../reference/skills.md) : `skill-claude-memory`,
  `skill-hook-creator`, `workflow-dev`, `workflow-debug` (`prompt-creator` et
  `subagent-creator` déjà présents). Brouillons de prompts archivés dans
  [`research/prompt-drafts.md`](../research/prompt-drafts.md).
- **Subagents** → cf. [`reference/subagents.md`](../reference/subagents.md) :
  `agent-explore-docs` / `-web` / `-code` (haiku), `agent-security-reviewer`
  (opus), `agent-code-java` / `-angular` (sonnet).
- **Hooks** → cf. [`reference/hooks.md`](../reference/hooks.md) : validation TS,
  validation Java, blocage migrations, ESLint/Prettier.

## Ordre d'implémentation recommandé

```
Phase 1 — Base (Immédiat)
├── ~/.claude/CLAUDE.md (global)         ← conventions personnelles
├── ./CLAUDE.md (projet)                 ← conventions d'équipe
├── LSP TypeScript + Java                ← code intelligence
└── /init sur chaque projet              ← CLAUDE.md auto-généré

Phase 2 — Extensions (Court terme)
├── .claude/rules/                       ← règles path-scopées
├── skill-claude-memory                  ← documentation CLAUDE.md
├── skill-hook-creator                   ← création de hooks
└── Hooks de validation (TS, Java)       ← qualité automatique

Phase 3 — Subagents & Workflows (Moyen terme)
├── agent-explore-docs / -code / -web    ← exploration isolée
├── workflow-dev (EPCT)                  ← Explore/Plan/Code/Test
├── workflow-debug                       ← debug structuré
└── MCP/CLI doc (ctx7)                   ← doc en temps réel

Phase 4 — Spécialisation (Long terme)
├── agent-code-java / agent-code-angular ← implémentation par stack
├── agent-security-reviewer             ← revue sécurité isolée
└── Agent Teams (expérimental)          ← orchestration avancée
```

## Références officielles

- [Best Practices](https://code.claude.com/docs/en/best-practices)
- [Extend Claude Code](https://code.claude.com/docs/en/features-overview)
- Fiches détaillées par brique → [`docs/reference/`](../reference/)
