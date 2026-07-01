# Step 4 — Verify (rôle `reviewer` + vérification multi-couches)

1. Dispatch `Agent(agent-review-adversarial)` avec le diff du correctif et,
   comme critère d'acceptation, le symptôme original + la cause racine
   tranchée à `steps/step-1-analyze.md`. Applique la règle `STATUS:` sur son
   retour.
2. Si une surface sensible est flaggée, escalade vers
   `Agent(agent-security-reviewer)` (même logique qu'à `workflow-dev` →
   `steps/step-4-review.md`).
3. **Vérification multi-couches** (pattern DEBUG officiel, étape 5) : confirme
   au minimum (a) le test de non-régression échoue sans le correctif et
   passe avec, (b) la suite complète reste verte, (c) la revue adversariale
   ne signale rien de sévérité haute. Montre la preuve, ne l'affirme pas.
4. Confirmation finale utilisateur (validation étape 5 du pattern DEBUG) :
   résume le symptôme, la cause racine, le correctif et les preuves de
   vérification, puis demande confirmation explicite avant de considérer le
   bug clos — ne déclare pas la boucle terminée de ta propre initiative si le
   correctif touche un comportement métier sensible. Ne lance pas de
   commit/push de ta propre initiative (voir `AGENTS.md`).
