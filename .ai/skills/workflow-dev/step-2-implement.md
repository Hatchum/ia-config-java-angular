# Step 2 — Implement (rôles `backend-coder` / `frontend-coder`)

1. Décide si la feature touche le backend, le frontend, ou les deux, à partir
   de la synthèse de `step-1-explore.md`.
2. Si les deux côtés sont concernés et touchent des fichiers disjoints
   (`workflow-dev.steps.implement-backend`/`implement-frontend` sont marqués
   `dispatch: parallel` entre eux dans `workflows.yaml`), dispatch
   `Agent(agent-code-java)` et `Agent(agent-code-angular)` dans le **même
   message**. Sinon, dispatch-les en séquence.
3. Dans chaque prompt de délégation, inclus : `archetype: feature`, la
   synthèse d'exploration, et la portée de la feature. Ne donne pas d'ordre
   contradictoire avec les conventions déjà chargées par l'agent
   (`.ai/rules/java-coding-rules.md` / `.ai/rules/angular-coding-rules.md`).
4. Applique la même règle `STATUS:` qu'à l'étape précédente sur chaque
   retour — `AskUserQuestion` avant toute suite si `blocked`/
   `needs_clarification`/malformé.
5. `implement-backend` et `implement-frontend` portent chacun un
   `verification_gate: true` dans `workflows.yaml` : un agent qui rapporte
   `STATUS: completed` doit avoir montré la commande de vérification réelle
   et son résultat (`scripts\test.cmd`/`mvn -q test` + `scripts\build.cmd`
   pour le Java ; `ng test` + `ng build` pour l'Angular) dans son résumé. Si
   ce n'est pas le cas, traite la réponse comme malformée (→
   `needs_clarification`) plutôt que de l'accepter sur la foi du seul token.
