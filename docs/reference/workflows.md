# Workflows

> Source vérifiée : [Best practices — Explore, plan, code](https://code.claude.com/docs/en/best-practices#explore-first-then-plan-then-code) · Vérifié le 2026-06-22
> Issu de l'éclatement de `docs/TASK.md` (archivé — voir `../guide/roadmap.md`).

## Principe : séparer exploration et implémentation

Laisser Claude coder directement peut résoudre le mauvais problème. Le workflow
recommandé sépare la recherche de l'exécution via le **plan mode**.

## Workflow EPCT (officiel)

```
Explore → Plan → (Implement) Code → (Test) Commit
```

1. **Explore** — Entrer en **plan mode** (lecture seule) : Claude lit les fichiers
   et répond, sans modifier.
   > `read /src/auth … understand how we handle sessions and login`
2. **Plan** — Demander un plan d'implémentation détaillé.
   `Ctrl+G` ouvre le plan dans l'éditeur pour l'éditer avant de valider.
3. **Code** — Sortir du plan mode et implémenter en suivant le plan, en
   vérifiant au fur et à mesure.
4. **Commit** — Demander un commit descriptif + une PR.

> Le plan mode ajoute de l'overhead. Pour une tâche au scope clair et au correctif
> petit (typo, log, renommage), demander directement. Le plan est surtout utile
> en cas d'incertitude sur l'approche, de changement multi-fichiers, ou de code
> méconnu. *« Si tu peux décrire le diff en une phrase, saute le plan. »*

## Donner un moyen de vérifier (clé)

Claude s'arrête quand « ça a l'air fini ». Fournir un **signal pass/fail** ferme
la boucle : suite de tests, code retour de build, linter, script de diff,
screenshot comparé. Niveaux de garantie croissants :
- **Dans un prompt** : « lance les tests et itère ».
- **Sur une session** : condition `/goal` (réévaluée à chaque tour).
- **Garde déterministe** : un [hook `Stop`](hooks.md) bloque la fin tant que le
  check échoue (Claude force la fin après 8 blocages consécutifs).
- **Second avis** : un subagent de revue en contexte frais (cf. `/code-review`).

Faire **montrer la preuve** (sortie de test, commande + résultat, screenshot)
plutôt qu'affirmer le succès.

## Workflows en fichiers séparés (pattern TASK.md)

Pour des workflows longs, les stocker dans des **fichiers d'étapes distincts**
sous un skill, pour que Claude lise chaque étape séquentiellement sans tout
charger d'un coup :

```
.claude/skills/workflow-dev/
  SKILL.md          # point d'entrée
  step-0-init.md
  step-1-explore.md
  step-2-plan.md
  step-3-code.md
  step-4-test.md
.claude/skills/workflow-debug/
  SKILL.md
  step-1-analyze.md
  step-1b-log-instrumentation.md
  step-2-find-solutions.md
  step-3-propose.md
  step-4-fix.md
  step-5-verify.md
```

## Workflow DEBUG (pattern TASK.md)

Principe clé : **tests qui passent ≠ fix qui marche** — exécuter le vrai chemin
de code. Technique de log : quand l'erreur n'est pas reproductible, ajouter des
logs stratégiques → l'utilisateur exécute et partage la console.

| Étape | Action | Validation utilisateur |
|---|---|---|
| 1 — Analyze | Reproduire, cause racine | Demander plus de contexte |
| 1b — Log | Logs de debug (optionnel) | L'utilisateur partage la sortie |
| 2 — Find | 2-3+ solutions, pros/cons | — |
| 3 — Propose | Présenter les options | L'utilisateur choisit |
| 4 — Fix | Implémenter | — |
| 5 — Verify | Vérification multi-couches | Confirmation utilisateur |

## Note — Dynamic workflows / revue adverse

Claude Code expose aussi des **dynamic workflows** (outil `Workflow`) qui
orchestrent des subagents en arrière-plan et renvoient un résultat consolidé. Et
une **étape de revue adverse** (un subagent voit seulement le diff + les
critères) avant de considérer le travail fini — cf. `/code-review` et
[subagents.md](subagents.md). Demander à ne signaler que les écarts affectant la
correction ou les exigences (sinon : sur-ingénierie).
