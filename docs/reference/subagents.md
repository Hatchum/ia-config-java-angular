# Subagents — `.claude/agents/`

> Source vérifiée : [Subagents](https://code.claude.com/docs/en/sub-agents) · Vérifié le 2026-06-22
> Issu de l'éclatement de `docs/TASK.md` (archivé — voir `../guide/roadmap.md`).

Un subagent tourne dans sa **propre fenêtre de contexte**, avec son system
prompt, ses outils et ses permissions, et ne retourne qu'un **résumé** à la
session principale. Idéal pour les tâches qui lisent beaucoup (exploration,
recherche, revue) sans polluer le contexte principal, ou pour router vers un
modèle moins cher (Haiku).

## Subagents intégrés

| Agent | Modèle | Outils | Rôle |
|---|---|---|---|
| **Explore** | Haiku | lecture seule | Recherche/analyse de code (saute CLAUDE.md + git status) |
| **Plan** | hérite | lecture seule | Recherche pendant le plan mode (saute CLAUDE.md + git status) |
| **general-purpose** | hérite | tous | Tâches complexes multi-étapes |

`statusline-setup` (Sonnet) et `claude-code-guide` (Haiku) sont aussi
disponibles.

## Emplacements & priorité

| Emplacement | Portée | Priorité |
|---|---|---|
| Managed settings | Organisation | 1 (max) |
| `--agents` (flag CLI, JSON) | Session | 2 |
| `.claude/agents/` | Projet | 3 |
| `~/.claude/agents/` | Tous vos projets | 4 |
| Plugin `agents/` | Où le plugin est activé | 5 |

L'identité vient du champ `name`, pas du chemin (sous-dossiers autorisés pour
l'organisation). Fichiers ajoutés/édités sur disque : **redémarrer la session**
(ou passer par `/agents`).

## Structure & frontmatter (référence officielle)

```markdown
---
name: code-reviewer            # requis (minuscules + tirets)
description: Quand déléguer à cet agent  # requis
tools: Read, Grep, Glob, Bash  # hérite tout si omis
disallowedTools: Write, Edit   # denylist (appliquée avant tools)
model: inherit                 # sonnet|opus|haiku|fable|<id>|inherit (défaut: inherit)
permissionMode: default        # default|acceptEdits|auto|dontAsk|bypassPermissions|plan
maxTurns: 20
skills: [api-conventions]      # contenu COMPLET préchargé au démarrage
mcpServers: [github]           # serveurs MCP scoppés à l'agent
hooks: { PreToolUse: [...] }   # hooks scoppés à l'agent
memory: project                # user|project|local — mémoire persistante
background: false
effort: high
isolation: worktree            # copie isolée du repo (git worktree)
color: blue
initialPrompt: "..."           # si lancé comme session principale (--agent)
---

System prompt de l'agent (devient le prompt système du subagent)...
```

> **Corrections vs TASK.md** :
> - `model` par défaut = **`inherit`** (pas `haiku`). Valeurs : `sonnet`, `opus`,
>   `haiku`, **`fable`**, un ID complet (`claude-opus-4-8`), ou `inherit`.
> - `permissionMode` a **6 valeurs** : `default`, `acceptEdits`, `auto`,
>   `dontAsk`, `bypassPermissions`, `plan` (TASK.md n'en listait que 3).
> - Pour précharger des skills, utiliser le champ **`skills`** (pas lister
>   `Skill` dans `tools`). Le contenu complet est injecté au démarrage.
> - Champs additionnels disponibles : `disallowedTools`, `mcpServers`, `memory`,
>   `background`, `effort`, `isolation`, `color`, `initialPrompt`.

### Outils non disponibles aux subagents
`AskUserQuestion`, `EnterPlanMode`, `ExitPlanMode` (sauf `permissionMode: plan`),
`ScheduleWakeup`, `WaitForMcpServers`.

## Choix du modèle (ordre de résolution)

1. `CLAUDE_CODE_SUBAGENT_MODEL` (env) → 2. modèle passé à l'invocation →
3. frontmatter `model` → 4. modèle de la conversation principale.

## Mémoire persistante

`memory: project` (recommandé) → `.claude/agent-memory/<name>/` (partagé git) ;
`user` → `~/.claude/agent-memory/<name>/` ; `local` → non versionné. Active
auto Read/Write/Edit et injecte les 200 premières lignes de `MEMORY.md`.

## Invocation

- **Langage naturel** : « Use the code-reviewer subagent to… » (Claude décide).
- **@-mention** : `@"code-reviewer (agent)" …` (garantit cet agent).
- **Session entière** : `claude --agent code-reviewer` ou `"agent"` dans `settings.json`.

`description` claire = délégation automatique. Ajouter « use proactively » pour
encourager la délégation.

## Subagent vs autres mécanismes

| Critère | Subagent | Agent Team (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) |
|---|---|---|
| Contexte | Isolé, retourne un résumé | Indépendant, communication peer-to-peer |
| Coût tokens | Faible (résumé) | Élevé (instances séparées) |
| Idéal pour | Tâche focalisée | Travail complexe, hypothèses concurrentes |

Un **fork** (`/fork`) hérite de toute la conversation (pas d'isolation
d'entrée) — pratique quand un subagent nommé aurait besoin de trop de contexte.
Un subagent peut spawner des subagents imbriqués (profondeur max 5).

## Subagents à créer (roadmap projet, repris de TASK.md)

| Agent | Modèle suggéré | Outils |
|---|---|---|
| `agent-explore-docs` | haiku | Read, Bash, find-docs/ctx7 |
| `agent-explore-web` | haiku | WebSearch, WebFetch |
| `agent-explore-code` | haiku | Read, Grep, Glob |
| `agent-security-reviewer` | opus | Read, Grep, Glob, Bash |
| `agent-code-java` | sonnet | + skills Java |
| `agent-code-angular` | sonnet | + skills Angular |

> Aide : le skill `subagent-creator` (présent dans ce dépôt) génère ces fichiers.
