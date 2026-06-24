---
name: workflow-dev
description: Run the EPCT-style feature workflow for this Java/Angular monorepo (explore, then implement backend/frontend, then an adversarial review) by dispatching the in-session subagents and role bindings defined in .ai/config/workflows.yaml's `workflow-dev` entry and .ai/config/subagents.yaml. Use whenever the user asks to implement, add, build, or extend a feature in this repo. Reacts to each subagent's `STATUS:` token and escalates to the human via AskUserQuestion on `blocked`/`needs_clarification` — never guesses past one.
argument-hint: "[description de la feature]"
---

# workflow-dev — boucle feature (EPCT à rôles)

Tu es l'**orchestrateur** : ce skill ne délègue pas son exécution à un
subagent (`AskUserQuestion` n'est pas disponible aux subagents — voir
`docs/research/agentique.md` §HITL). Tu restes la session principale du
début à la fin.

La feature à traiter : `$ARGUMENTS` (ou ce que l'utilisateur vient de
demander si `$ARGUMENTS` est vide).

## Comment lire ce skill

Les étapes sont des fichiers séparés pour ne pas tout charger d'un coup
(pattern documenté dans `docs/reference/workflows.md`). Lis et applique
**un fichier à la fois**, dans cet ordre, avec l'outil `Read` :

1. `step-0-init.md` — charger la config, fixer l'archétype et le workflow
2. `step-1-explore.md` — rôle `researcher`, dispatch parallèle
3. `step-2-implement.md` — rôles `backend-coder`/`frontend-coder`
4. `step-3-review.md` — rôle `reviewer`
5. `step-4-report.md` — rapport final à l'utilisateur

Ne passe à l'étape suivante que si l'étape courante s'est terminée sans
escalade en attente (voir la règle `STATUS:` dans chaque step file et dans
`.ai/config/subagents.yaml` → `hitl:`).
