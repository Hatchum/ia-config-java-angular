---
name: feature
description: Run the spec-driven feature workflow for this Java/Angular monorepo (explore the code, ask the human every clarifying question, get a spec approved, then implement backend/frontend against its acceptance criteria, then an adversarial review) by dispatching the in-session subagents and role bindings defined in .ai/config/workflows.yaml's `workflow-dev` entry and .ai/config/subagents.yaml. Use whenever the user asks to implement, add, build, or extend a feature in this repo. Pauses at the `specify` checkpoint until the human approves the spec; reacts to each subagent's `STATUS:` token and escalates via AskUserQuestion on `blocked`/`needs_clarification` — never guesses past one.
argument-hint: "[description de la feature]"
---

# feature — boucle feature spec-driven (EPCT à rôles + gate de spec)

Tu es l'**orchestrateur** : ce skill ne délègue pas son exécution à un
subagent (`AskUserQuestion` n'est pas disponible aux subagents — voir
`docs/research/agentique.md` §HITL). Tu restes la session principale du
début à la fin.

**Principe spec-driven** : rien ne s'implémente sans une **spec approuvée
par l'utilisateur** (`docs/specs/<slug>.md` — objectif, portée, critères
d'acceptation). L'exploration du code vient d'abord (elle ancre les
questions dans la réalité du dépôt), puis tu poses **toutes** les questions
nécessaires, puis tu écris la spec et la fais valider. Les critères
d'acceptation de la spec sont le contrat de l'implémentation ET de la revue.

La feature à traiter : `$ARGUMENTS` (ou ce que l'utilisateur vient de
demander si `$ARGUMENTS` est vide).

## Comment lire ce skill

Les étapes sont des fichiers séparés pour ne pas tout charger d'un coup
(pattern documenté dans `docs/reference/workflows.md`). Lis et applique
**un fichier à la fois**, dans cet ordre, avec l'outil `Read` :

1. `steps/step-0-init.md` — charger la config, fixer l'archétype et le workflow
2. `steps/step-1-explore.md` — rôle `researcher`, dispatch parallèle + collecte
   des questions ouvertes
3. `steps/step-2-specify.md` — **checkpoint spec** (toi) : questions → spec →
   approbation utilisateur
4. `steps/step-3-implement.md` — rôles `backend-coder`/`frontend-coder`, contrat =
   la spec approuvée
5. `steps/step-4-review.md` — rôle `reviewer`, diff vs critères d'acceptation de
   la spec
6. `steps/step-5-report.md` — rapport final à l'utilisateur, critère par critère

Ne passe à l'étape suivante que si l'étape courante s'est terminée sans
escalade en attente (voir la règle `STATUS:` dans chaque step file et dans
`.ai/config/subagents.yaml` → `hitl:`).
