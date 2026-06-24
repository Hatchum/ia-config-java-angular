# Step 1 — Analyze (rôle `researcher`, + Log optionnel)

1. Dispatch `Agent(agent-explore-code)` (et `agent-explore-docs`/
   `agent-explore-web` seulement si une lib externe est suspectée) avec :
   `archetype: bug-fix`, le message d'erreur/trace/test en échec rassemblés à
   `step-0-init.md`. Demande-lui explicitement de **reproduire** la
   défaillance et de remonter les preuves (chemin, ligne, code implicite),
   pas de la corriger.
2. Si la défaillance n'est pas reproductible à partir des informations
   disponibles (cas « Log » du pattern DEBUG officiel), demande au
   researcher de proposer des points de log stratégiques plutôt que de
   deviner — puis `AskUserQuestion` pour demander à l'utilisateur de
   relancer et partager la sortie console. Ne continue pas sans repro.
3. Applique la règle `STATUS:` sur le retour : `blocked`/
   `needs_clarification`/malformé → `AskUserQuestion` avant de continuer.
4. Une fois la défaillance reproduite et une piste de cause identifiée,
   passe à `step-2-propose.md`.
