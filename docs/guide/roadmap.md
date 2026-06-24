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
  `skill-hook-creator` restent à créer ; `workflow-dev`, `workflow-debug`
  (`prompt-creator` et `subagent-creator` déjà présents) sont **✅ créés** —
  voir [`research/agentique.md`](../research/agentique.md). Brouillons de
  prompts archivés dans [`research/prompt-drafts.md`](../research/prompt-drafts.md).
- **Subagents** → cf. [`reference/subagents.md`](../reference/subagents.md) :
  `agent-explore-docs` / `-web` / `-code` (haiku), `agent-security-reviewer`
  (opus), `agent-code-java` / `-angular` (sonnet) sont **✅ créés**, plus
  `agent-review-adversarial` (sonnet, nouveau) — voir
  [`research/agentique.md`](../research/agentique.md). Reste à faire :
  étendre `scripts/sync-config.py` pour générer/valider
  `.ai/config/workflows.yaml`/`subagents.yaml` (voir agentique.md tâche P1).
- **Hooks** → cf. [`reference/hooks.md`](../reference/hooks.md) : validation TS,
  validation Java, blocage migrations, ESLint/Prettier ; + un hook `Stop` de
  gate build/tests proposé dans [`research/agentique.md`](../research/agentique.md) (tâche P4).

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

Phase 3 — Subagents & Workflows (Moyen terme)               [✅ fait — voir research/agentique.md]
├── agent-explore-docs / -code / -web    ← exploration isolée
├── workflow-dev (EPCT)                  ← Explore/Code(back+front)/Review
├── workflow-debug                       ← debug structuré (Propose/Verify côté orchestrateur)
└── MCP/CLI doc (ctx7)                   ← doc en temps réel (find-docs, déjà fait)

Phase 4 — Spécialisation (Long terme)                        [✅ fait — voir research/agentique.md]
├── agent-code-java / agent-code-angular ← implémentation par stack
├── agent-review-adversarial             ← gate de revue routinier (nouveau)
├── agent-security-reviewer             ← revue sécurité isolée (escalade manuelle)
└── Agent Teams (expérimental)          ← orchestration avancée — toujours en proposition future
```

## Références officielles

- [Best Practices](https://code.claude.com/docs/en/best-practices)
- [Extend Claude Code](https://code.claude.com/docs/en/features-overview)
- Fiches détaillées par brique → [`docs/reference/`](../reference/)
