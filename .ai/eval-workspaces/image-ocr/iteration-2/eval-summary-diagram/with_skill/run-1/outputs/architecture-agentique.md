# Architecture agentique

Comment Claude Code délègue à des sous-agents pour des tâches complexes

Claude Code utilise le "Task tool" pour déléguer du travail à des sous-agents (subagents).

- Chaque sous-agent a besoin de 5 éléments :
  - Tourne dans son propre contexte **isolé**
  - Possède ses propes outils autorisés
  - Ne peut **PAS** spawner d'autres sous-agents (pa l'imbrication)
  - Retourne un résultat texte unique au Head Agent.

## Types de relations

- **Head Agent** lance N agents simultanément
  - → Recherche multi-sources, exploration large
  - → Jusqu'à 7 agents simultanés max
- 2. **Séquentielle** (Pipeline)
  - → Agent A termine → résultat → Agent B démarre
- 3. **Hybride** (Fan-Out puis **Pipeline**)
  - → Agents A+B en parallèle → résultats → Agent C

Un seul sub-agent par tâche + retour d'un texte unique seul vers le Head Agent

## Diagramme

- **HEAD AGENT** (Orchestrateur)
  - **PARALLÈLE** — lance deux agents en même temps, sans dépendance entre eux :
    - **AGENT 1** — Recherche Générale
    - **AGENT 2** — Sources Officielles
  - **PARALLÈLE** (convergence) → **AGENT 3** — ne démarre qu'une fois Agent 1 *et* Agent 2 terminés ; combine leurs résultats (icônes d'outils/données sous le libellé du bloc)
    - Encart illustrant le même motif en miniature (rectangle en pointillés relié à Agent 3 et à Agent 3 Synthèse) :
      - **AGENT 1** — Recherche → **AGENT 2** — Sources Officielles (liaison séquentielle figurée à l'intérieur de l'encart)
      - **SÉQUENTIEL** → **AGENT 3 Synthèse** (lancé APRÈS 1 et 2) — étape de synthèse qui attend que les deux agents précédents aient fini avant de combiner leurs résultats

## Résumé

Le schéma illustre comment le Head Agent (orchestrateur) délègue une tâche complexe à des sous-agents via le "Task tool" de Claude Code. Il lance d'abord deux agents en parallèle et sans dépendance l'un envers l'autre : Agent 1 (recherche générale) et Agent 2 (sources officielles). Une fois que ces deux agents ont terminé, un troisième agent — Agent 3 — démarre : c'est un point de jonction/synthèse, donc séquentiel par rapport aux deux premiers, qui combine leurs résultats respectifs (texte explicite : « lancé APRÈS 1 et 2 »). Le schéma reprend ainsi visuellement le motif décrit dans le texte sous le nom « Hybride (Fan-Out puis Pipeline) » : deux agents en éventail (fan-out) suivis d'un agent de pipeline qui synthétise leurs sorties. Chaque sous-agent travaille dans son propre contexte isolé, ne peut pas créer d'autres sous-agents, et ne renvoie au Head Agent qu'un seul résultat texte final.
