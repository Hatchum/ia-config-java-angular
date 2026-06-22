# Automatisation & scaling

> Source vérifiée : [Best practices — Automate and scale](https://code.claude.com/docs/en/best-practices#automate-and-scale) · Vérifié le 2026-06-22
> Issu de l'éclatement de `docs/TASK.md` (archivé — voir `../guide/roadmap.md`).

Une fois efficace avec une session, multiplier la production via le mode
non-interactif et les sessions parallèles.

## Mode non-interactif (CI / scripts)

```bash
# Requête ponctuelle
claude -p "Explique ce que fait ce projet"

# Sortie structurée pour scripts
claude -p "Liste tous les endpoints API" --output-format json

# Streaming pour traitement temps réel
claude -p "Analyse ce log" --output-format stream-json --verbose | ma_commande

# Mode auto pour CI (classifier de sécurité intégré)
claude --permission-mode auto -p "fix all lint errors"
```

- Formats : `text` (défaut), `json`, `stream-json` (+ `--verbose`).
- `--permission-mode auto` : un modèle classifier bloque escalade de scope,
  infra inconnue, actions pilotées par contenu hostile. En `-p`, il **abandonne**
  si les blocages se répètent (pas d'utilisateur de repli).
- `--verbose` : pour le debug en dev, à couper en prod.

## Sessions parallèles

| Approche | Pour |
|---|---|
| [Worktrees](https://code.claude.com/docs/en/worktrees) | Sessions CLI en checkouts git isolés |
| App Desktop | Gestion visuelle de sessions locales |
| Claude Code on the web | Sessions sur VM cloud isolées |
| [Agent teams](https://code.claude.com/docs/en/agent-teams) | Coordination auto (tâches + messagerie partagées) — expérimental |

### Pattern Writer/Reviewer

- **Session A (Writer)** : implémente.
- **Session B (Reviewer)** : revoit en **contexte frais** (pas de biais envers le
  code qu'elle vient d'écrire).

Variante : un Claude écrit les tests, un autre écrit le code pour les faire
passer.

## Fan-out sur des fichiers en masse

```bash
# 1) générer la liste, 2) boucler
for file in $(cat files.txt); do
  claude -p "Migrate $file de React à Vue. Retourne OK ou FAIL." \
    --allowedTools "Edit,Bash(git commit *)"
done
```

Tester sur 2-3 fichiers, affiner le prompt, puis lancer à l'échelle.
`--allowedTools` restreint ce que Claude peut faire (crucial en non-surveillé).

## Étape de revue adverse

Avant de considérer une tâche finie, faire revoir le diff par un subagent en
contexte frais (`/code-review`, ou prompt explicite contre `PLAN.md`). Ne
réclamer que les écarts affectant la correction/les exigences. Pour des runs
autonomes longs, un **agent team** maintient cette boucle.

## Loops & tâches planifiées

- `/loop <intervalle> <commande>` : exécuter une commande sur un intervalle
  récurrent (ou auto-cadencé sans intervalle).
- `/schedule` : agents cloud planifiés (cron). Voir aussi les outils `Cron*`.
