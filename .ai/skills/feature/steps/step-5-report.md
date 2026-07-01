# Step 5 — Rapport final

1. Mets à jour la spec (`docs/specs/<slug>.md`) : coche chaque critère
   d'acceptation réellement satisfait et passe `Status: implemented`. Un
   critère non couvert reste décoché et doit être signalé explicitement —
   jamais coché sur la foi d'une affirmation non vérifiée.
2. Résume à l'utilisateur, en quelques lignes (pas de répétition des résumés
   intermédiaires déjà visibles dans la conversation) :

- le bilan **critère par critère** de la spec (satisfait / non couvert,
  avec la preuve) ;
- ce qui a été implémenté (fichiers backend/frontend touchés) ;
- la preuve de vérification réellement observée (pas affirmée) — commande +
  résultat build/tests ;
- le résultat de la revue (`agent-review-adversarial`, et
  `agent-security-reviewer` si escaladé) ;
- toute décision que l'utilisateur a tranchée en cours de route via
  `AskUserQuestion` (déjà journalisée dans la spec, section « Resolved
  questions »).

Ne lance pas de commit/push de ta propre initiative à cette étape — c'est une
action visible/partagée qui suit les règles habituelles de confirmation de
ce kit (voir `AGENTS.md`), pas un sous-pas implicite de ce skill.
