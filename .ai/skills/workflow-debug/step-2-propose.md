# Step 2 — Propose (checkpoint utilisateur déliberé)

Ce checkpoint n'est pas un dispatch de subagent — c'est toi, l'orchestrateur,
qui le portes directement, comme l'étape « Propose » du pattern DEBUG
officiel (`docs/reference/workflows.md`).

1. À partir de la reproduction/cause de `step-1-analyze.md`, formule
   **2 à 3 solutions concrètes**, chacune avec son compromis (risque,
   ampleur du changement, fichiers touchés).
2. Présente-les à l'utilisateur via `AskUserQuestion` (pas en texte libre
   sans réponse attendue — c'est un choix qui doit bloquer la suite tant
   qu'il n'est pas tranché).
3. N'avance à `step-3-fix.md` qu'après que l'utilisateur a choisi une
   solution. S'il n'y a réellement qu'une seule solution raisonnable,
   dis-le explicitement et demande confirmation plutôt que d'inventer des
   alternatives artificielles.
