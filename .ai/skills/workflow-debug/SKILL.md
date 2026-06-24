---
name: workflow-debug
description: Run the DEBUG loop for this Java/Angular monorepo (reproduce + root-cause, propose 2-3 solutions for the human to pick, fix, multi-layer verify) by dispatching the in-session subagents and role bindings defined in .ai/config/workflows.yaml's `workflow-debug` entry and .ai/config/subagents.yaml. Use whenever the user reports a bug, a failing test, or unexpected behavior and wants it fixed. Pauses for a deliberate human choice between candidate fixes, and reacts to each subagent's `STATUS:` token, escalating via AskUserQuestion on `blocked`/`needs_clarification`.
argument-hint: "[description du bug / test en échec / trace]"
---

# workflow-debug — boucle bug-fix (DEBUG à rôles)

Tu es l'**orchestrateur** : ce skill ne délègue pas son exécution à un
subagent (`AskUserQuestion` n'est pas disponible aux subagents). Tu restes
la session principale du début à la fin.

Le bug à traiter : `$ARGUMENTS` (ou ce que l'utilisateur vient de décrire).

Ce skill suit le pattern DEBUG officiel documenté dans
`docs/reference/workflows.md` (Analyze → Log → Find → Propose → Fix →
Verify, validation utilisateur aux étapes 1/3/5) en le mappant sur les 3
rôles de `workflows.yaml` → `workflow-debug` (`analyze: researcher` →
`fix: backend-coder|frontend-coder` → `review: reviewer`) : les checkpoints
« Propose » et « Verify » sont portés par l'orchestrateur lui-même (toi),
pas par un subagent dédié — c'est pour ça qu'il y a 5 step files pour 3
rôles.

## Comment lire ce skill

Lis et applique **un fichier à la fois**, dans cet ordre, avec l'outil
`Read` :

1. `step-0-init.md` — charger la config, fixer l'archétype et le workflow
2. `step-1-analyze.md` — rôle `researcher` : reproduire + cause probable
3. `step-2-propose.md` — checkpoint utilisateur : choix entre 2-3 solutions
4. `step-3-fix.md` — rôle `backend-coder`/`frontend-coder`
5. `step-4-verify.md` — rôle `reviewer` + vérification multi-couches +
   confirmation finale utilisateur

Ne passe à l'étape suivante que si l'étape courante s'est terminée sans
escalade en attente.
