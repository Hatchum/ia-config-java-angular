# Modèles — choix stratégique

> Sources : [Subagents — choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model) · [Model config](https://code.claude.com/docs/en/model-config) · Vérifié le 2026-06-22
> Issu de l'éclatement de `docs/TASK.md` (archivé — voir `../guide/roadmap.md`).

## Alias & IDs

| Alias | ID complet | Profil |
|---|---|---|
| `opus` | `claude-opus-4-8` | Architecture, raisonnement profond, sécurité |
| `sonnet` | `claude-sonnet-4-6` | Code, écriture, implémentation (équilibre) |
| `haiku` | `claude-haiku-4-5-20251001` | Recherche, classification, exploration (rapide/peu cher) |
| `fable` | `claude-fable-5` | Modèle Fable (récent) |
| `inherit` | — | Même modèle que la conversation principale |

> Ces alias sont acceptés partout : frontmatter `model` des [skills](skills.md) /
> [subagents](subagents.md), flag `--model`, commande `/model`. Pour les apps IA,
> viser par défaut les modèles Claude les plus récents et capables.

## Règle pratique

| Usage | Modèle |
|---|---|
| Agents explore (code/docs/web) | **Haiku** (rapide, peu cher) |
| Agents code (implémentation) | **Sonnet** (performance/coût) |
| Revues sécurité, architecture | **Opus** (précision max) |

## Où le configurer

- **Subagent** : champ `model` du frontmatter (défaut `inherit`). Ordre de
  résolution : env `CLAUDE_CODE_SUBAGENT_MODEL` → param d'invocation → frontmatter
  → modèle principal.
- **Skill** : champ `model` (override pour le tour courant uniquement) + `effort`
  (`low|medium|high|xhigh|max`).
- **Session** : `/model` ou flag `--model`.

## Effort (niveau de raisonnement)

Indépendant du modèle : `low`, `medium`, `high`, `xhigh`, `max` (selon le
modèle). Configurable par session, ou par skill/subagent via `effort`. Inclure
`ultrathink` dans un skill demande un raisonnement plus profond ponctuel.

## Fast mode (Claude Code)

`/fast` accélère la sortie en gardant Opus (ne rétrograde pas vers un petit
modèle). Disponible sur Opus 4.8 / 4.7 / 4.6.
