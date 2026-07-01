# Step 2 — Specify (checkpoint spec-driven, porté par l'orchestrateur)

Ce checkpoint n'est **pas** un dispatch de subagent — c'est toi,
l'orchestrateur, qui le portes directement (`carried_by: orchestrator` dans
`workflows.yaml`), car `AskUserQuestion` est indisponible aux subagents.
C'est le cœur du **spec-driven development** de ce kit : **aucune ligne de
code n'est écrite tant que la spec n'est pas approuvée par l'utilisateur.**

1. **Collecte les inconnues.** Rassemble en une liste unique :
   - les « Open questions » remontées par chaque researcher à
     `step-1-explore.md` ;
   - tes propres zones d'ombre en brouillonnant la spec (portée ambiguë,
     comportement aux limites, cas d'erreur, impacts UI/API/données,
     compatibilité, critères de succès non mesurables…). Si un point peut se
     déduire du code ou des conventions du dépôt, déduis-le et note-le comme
     décision proposée — ne le transforme pas en question.
2. **Pose TOUTES les questions restantes** via `AskUserQuestion`, par lots
   (jusqu'à 4 questions par appel, avec des options concrètes tirées de
   l'exploration — pas des questions ouvertes vagues). Itère : si une réponse
   ouvre une nouvelle question, repose-la au lot suivant. Ne devine jamais à
   la place de l'utilisateur sur la portée, le comportement attendu ou un
   compromis — c'est exactement ce que ce checkpoint doit empêcher.
3. **Rédige la spec** à partir de `spec-template.md` (même dossier), dans la
   langue de l'équipe, et enregistre-la dans
   `docs/specs/<YYYY-MM-DD>-<slug>.md` du projet (crée le dossier au besoin).
   Chaque critère d'acceptation doit être **observable et testable** — c'est
   le contrat que `step-3-implement.md` exécutera et que `step-4-review.md`
   vérifiera.
4. **Fais approuver la spec** via `AskUserQuestion` (options : approuver /
   amender). En cas d'amendement, applique-le et re-présente — n'avance
   jamais sur une spec non approuvée. Marque alors `Status: approved` dans
   le fichier.
5. Passe à `step-3-implement.md` en emportant le chemin de la spec approuvée.
