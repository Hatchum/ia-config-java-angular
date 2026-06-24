# Step 3 — Review (rôle `reviewer`, gate de fin de boucle)

1. Dispatch `Agent(agent-review-adversarial)` (séquentiel, dépend des
   résultats de `step-2-implement.md`) avec : le diff produit (ou demande-lui
   de lancer `git diff` lui-même) et les critères d'acceptation de la
   feature.
2. Applique la règle `STATUS:` sur son retour.
3. Si son résumé signale une surface sensible (auth, crypto, paiement,
   désérialisation, I/O fichier piloté par l'utilisateur), dispatch en plus
   `Agent(agent-security-reviewer)` avant de continuer — c'est l'escalade
   volontaire documentée dans `.ai/config/subagents.yaml` →
   `hitl.escalation_note`, pas une étape automatique du workflow.
4. S'il y a un finding de sévérité haute : ne le corrige pas toi-même en
   silence — soit redispatch le rôle `backend-coder`/`frontend-coder`
   concerné avec le finding précis, soit `AskUserQuestion` si le correctif
   implique un choix (ex. changer une décision d'architecture).
5. Une fois la revue propre (aucun finding haute sévérité, ou tous corrigés
   et re-vérifiés), passe à `step-4-report.md`.
