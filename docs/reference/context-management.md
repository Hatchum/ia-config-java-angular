# Gestion du contexte & sessions

> Source vérifiée : [Best practices — Manage your session](https://code.claude.com/docs/en/best-practices#manage-your-session) · Vérifié le 2026-06-22
> Issu de l'éclatement de `docs/TASK.md` (archivé — voir `../guide/roadmap.md`).

**La fenêtre de contexte est la ressource la plus critique.** Les performances se
dégradent quand elle se remplit (Claude « oublie » des instructions, fait plus
d'erreurs). Tout le contexte (messages, fichiers lus, sorties de commandes) y
réside.

## Commandes & raccourcis essentiels

| Commande / touche | Usage |
|---|---|
| `/clear` | Réinitialiser le contexte entre tâches non liées |
| `/compact <focus>` | Compacter avec consigne : `/compact Focus sur les changements API` |
| `/rewind` ou `Esc Esc` | Menu rewind : restaurer conversation / code / les deux, ou résumer depuis/jusqu'à un message |
| `Esc` | Stopper Claude en cours (contexte préservé) |
| `Ctrl+G` | Ouvrir le plan dans l'éditeur (édition directe) |
| `Ctrl+B` | Passer une tâche en arrière-plan |
| `/btw` | Question rapide en overlay éphémère (n'entre pas dans l'historique) |
| `/rename` | Nommer la session (la retrouver via `--resume`) |
| `/memory` | Lister/éditer CLAUDE.md, rules, auto memory |

## Sessions

```bash
claude --continue   # reprendre la session la plus récente
claude --resume     # choisir dans la liste
```

Nommer les sessions comme des branches (`oauth-migration`). Les **checkpoints**
sont créés à chaque prompt : on peut tenter une approche risquée puis rewind.
⚠️ Les checkpoints ne tracent que les changements **faits par Claude** — ce
n'est pas un substitut à git.

## Compaction

Auto-compaction quand on approche des limites (préserve code, patterns, décisions
clés). Personnalisable depuis CLAUDE.md (« lors de la compaction, toujours
préserver la liste des fichiers modifiés et les commandes de test »). Le
CLAUDE.md racine est **re-injecté** après `/compact` ; pas les CLAUDE.md de
sous-dossiers (rechargés à la prochaine lecture de fichier).

## Anti-patterns (et correctifs)

| Anti-pattern | Symptôme | Fix |
|---|---|---|
| Session fourre-tout | Tâches non liées mélangées | `/clear` entre tâches |
| Corrections répétées | Même erreur ×2 | Après 2 échecs : `/clear` + prompt réécrit |
| CLAUDE.md surchargé | > 200 lignes, règles ignorées | Pruner sans pitié → skills/rules/hooks |
| Exploration infinie | Lit des centaines de fichiers | Scope précis + subagents |
| Trust-then-verify | Implémentation non vérifiée | Fournir tests/scripts/screenshots |

## Réduire le contexte

- **Subagents** pour la recherche/exploration (rapportent un résumé) — le levier
  le plus puissant. Voir [subagents.md](subagents.md).
- Référencer les fichiers avec `@` (Claude lit avant de répondre).
- Les [rules path-scopées](rules.md) et [skills](skills.md) ne chargent qu'au
  besoin.
- Suivre l'usage du contexte avec une status line custom (`/statusline`).

> Cache de prompt : se réinitialise notamment au changement de modèle, à l'ajout
> d'un MCP, ou après un délai d'inactivité. Garder le modèle stable pendant une
> tâche réduit les coûts.
