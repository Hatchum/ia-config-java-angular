# Step 0 — Init

1. Lis `.ai/config/workflows.yaml` → `workflows.workflow-dev` (les 5 étapes
   `explore`/`specify`/`implement-backend`/`implement-frontend`/`review`,
   leur `dispatch`, `depends_on`, `carried_by`,
   `verification_gate`/`verification`) et
   `default_archetype_workflow.feature` (doit valoir `workflow-dev` — sinon
   un humain a peut-être déjà surchargé l'archétype par invocation : dans ce
   cas suis l'autre workflow nommé, pas celui-ci).
2. Lis `.ai/config/subagents.yaml` → `roles:` (mapping rôle → subagents),
   `sop:` (pour savoir quelle anatomie/`flavor` chaque rôle doit charger pour
   l'archétype `feature`), et `hitl:` (convention `STATUS:` + règle de
   décision — tu vas l'appliquer après **chaque** retour de subagent dans les
   steps suivants).
3. Fixe l'**archétype = `feature`** pour toute la suite. Si l'utilisateur a
   explicitement demandé un autre pattern (« fais ça en debug », « lance une
   simple revue ») malgré le déclenchement de ce skill, arrête-toi ici et
   bascule vers `workflow-debug` ou une revue ponctuelle (`agent-review-
   adversarial` seul) à la place — ne force pas `workflow-dev` contre la
   demande explicite.
4. Note en une phrase la portée de la feature (ce que tu vas transmettre aux
   subagents dans leur prompt de délégation) avant de passer à
   `steps/step-1-explore.md`.
