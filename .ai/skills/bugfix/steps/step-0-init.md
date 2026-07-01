# Step 0 — Init

1. Lis `.ai/config/workflows.yaml` → `workflows.workflow-debug` (les 5
   étapes `analyze`/`propose`/`fix`/`review`/`confirm` — tout séquentiel
   ici ; `propose` et `confirm` sont des checkpoints `carried_by:
   orchestrator`, portés par toi — et leur `verification`) et
   `default_archetype_workflow.bug-fix` (doit valoir `workflow-debug` ;
   sinon un humain a peut-être surchargé l'archétype par invocation — dans
   ce cas suis l'autre workflow nommé).
2. Lis `.ai/config/subagents.yaml` → `roles:`, `sop:` (anatomie/`flavor` de
   chaque rôle pour l'archétype `bug-fix`), et `hitl:` (convention `STATUS:`
   + règle de décision, à appliquer après chaque retour de subagent).
3. Fixe l'**archétype = `bug-fix`** pour toute la suite.
4. Rassemble ce que l'utilisateur a déjà fourni : message d'erreur, trace,
   nom du test en échec, étapes de reproduction. S'il manque l'essentiel
   pour même démarrer une investigation (aucune trace, aucun symptôme
   observable), `AskUserQuestion` **ici, avant de dispatcher quoi que ce
   soit** — ne lance pas un `researcher` à l'aveugle.
