# Architecture agentique

Comment Claude Code délègue à des sous-agents pour des tâches complexes

Claude Code utilise le "Task tool" pour déléguer du travail à des sous-agents (subagents).

- Chaque sous-agent a besoin de 5 éléments :
  - Tourne dans son propre contexte **isolé**
  - Possède ses propres outils autorisés
  - Ne peut **PAS** spawner d'autres sous-agents (pas l'imbrication)
  - Retourne un résultat texte unique au Head Agent

## Types de relations

- **Head Agent** lance N agents simultanément
  → Recherche multi-sources, exploration large
  → Jusqu'à 7 agents simultanés max
- **2. Séquentielle** (Pipeline)
  → Agent A termine → résultat → Agent B démarre
- **3. Hybride** (Fan-Out puis **Pipeline**)
  → Agents A+B en parallèle → résultats → Agent C

Un seul sub-agent par tâche + retour d'un texte unique seul vers le Head Agent.

## Diagramme

- **HEAD AGENT** (Orchestrateur)
  - PARALLÈLE — démarre deux agents en même temps, sans dépendance entre eux :
    - **AGENT 1** — Recherche Générale
    - **AGENT 2** — Sources Officielles
  - PARALLÈLE → **AGENT 3** (icônes d'outils/communication) — point de jonction qui reçoit les résultats combinés d'AGENT 1 et AGENT 2 une fois que les deux ont terminé
    - Encadré en pointillés illustrant le même schéma à plus petite échelle (exemple détaillé du fan-out/pipeline) :
      - **AGENT 1** — Recherche *(s'exécute en parallèle avec Agent 2 ci-dessous)*
      - **AGENT 2** — Sources Officielles *(en parallèle avec Agent 1)*
      - SÉQUENTIEL → **AGENT 3 Synthèse** (lancé APRÈS 1 et 2) — étape suivante, ne démarre qu'une fois que les résultats d'Agent 1 *et* Agent 2 sont disponibles
- Retour d'un texte unique seul vers le Head Agent — résultat final renvoyé par Agent 3 Synthèse à HEAD AGENT.

**Lecture du flux** : Agent 1 et Agent 2 démarrent toujours ensemble (parallèle, sans dépendance mutuelle) ; Agent 3 est un point de synthèse qui attend que les deux soient terminés avant de combiner leurs résultats (séquentiel par rapport à eux) ; Agent 3 Synthèse ne se déclenche qu'après cette jonction, puis renvoie un texte unique au Head Agent.
