# Step 1 — Explore (rôle `researcher`, dispatch parallèle)

1. Choisis, parmi `roles.researcher` (`agent-explore-code`,
   `agent-explore-docs`, `agent-explore-web`), les subagents réellement utiles
   à cette feature — typiquement `agent-explore-code` systématiquement, et
   `agent-explore-docs`/`agent-explore-web` seulement si une lib/API externe
   est en jeu.
2. Dispatch-les **en un seul message** (plusieurs appels `Agent` indépendants
   = le cas parallèle documenté dans `docs/research/agentique.md` §Contexte).
   Dans le prompt de délégation de chacun, indique explicitement
   `archetype: feature`, la portée notée à `steps/step-0-init.md`, et demande-lui
   de terminer son résumé par une section **« Open questions »** listant les
   ambiguïtés que seul l'utilisateur peut trancher (portée, comportement
   attendu, compromis) — matière première du checkpoint spec de
   `steps/step-2-specify.md`.
3. Pour CHAQUE retour de subagent, lis sa dernière ligne non vide et applique
   la règle de `.ai/config/subagents.yaml` → `hitl:` :
   - `STATUS: completed` → garde le résumé pour l'étape suivante.
   - `STATUS: blocked — ...` ou `STATUS: needs_clarification — ...` → appelle
     `AskUserQuestion` **avant** de dispatcher quoi que ce soit d'autre, avec
     la raison/question verbatim. N'avance qu'après réponse de l'utilisateur.
   - Ligne absente/mal formée → traite comme `needs_clarification` (filet de
     sécurité), `AskUserQuestion`.
4. Une fois tous les retours `completed`, synthétise en quelques lignes les
   fichiers/points d'intégration trouvés et **fusionne les « Open
   questions »** de tous les researchers en une liste dédupliquée — le tout
   alimente `steps/step-2-specify.md` (la synthèse ira ensuite aux rôles
   `backend-coder`/`frontend-coder` à `steps/step-3-implement.md`).
