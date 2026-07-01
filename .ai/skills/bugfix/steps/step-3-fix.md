# Step 3 — Fix (rôle `backend-coder` ou `frontend-coder`)

1. Choisis `agent-code-java` ou `agent-code-angular` selon la pile du bug
   (`roles.backend-coder`/`roles.frontend-coder` dans `subagents.yaml`).
2. Dispatch-le avec : `archetype: bug-fix`, la cause racine identifiée à
   `steps/step-1-analyze.md`, et la solution choisie par l'utilisateur à
   `steps/step-2-propose.md`. Demande explicitement le plus petit correctif
   correct, plus un test de non-régression qui échoue avant et passe après.
3. Applique la règle `STATUS:` sur le retour. `verification_gate: true` pour
   cette étape dans `workflows.yaml` : n'accepte `STATUS: completed` que si
   le résumé montre réellement la commande de vérification et son résultat
   (suite complète verte) — sinon, traite comme malformé →
   `needs_clarification`.
4. Une fois le correctif vérifié, passe à `steps/step-4-verify.md`.
