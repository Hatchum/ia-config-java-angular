# architecture-agentique.png — Texte extrait et résumé

Source : `a_trier/agents/architecture-agentique.png`

## Texte extrait (OCR)

**Titre :** Architecture agentique
**Sous-titre :** Comment Claude Code délègue à des sous-agents pour des tâches complexes

Claude Code utilise le "Task tool" pour déléguer du travail à des
sous-agents (subagents) :
- Chaque sous-agent a besoin de l'étapes
- Tourne dans son propre contexte isolé
- Possède ses propres outils autorisés
- Pas (de) PRO spawner d'autres sous-agents (limitation)
- Retourne un résultat texte unique au Head Agent

**Types de relations :**
- **Head Agent** lance N agents simultanément
- **Parallèle** multi-tools, executoration large
  - Jusqu'à 7 agents simultanés max
- **Séquentiel (Pipeline)**
  - Agent A termine → résultat → Agent B démarre
- **Hybride (Fan-Out puis Pipeline)**
  - Agents A+B en parallèle → résultats → Agent C

**Légende :** Un seul sous-agent par tâche → retour d'écrit vers le Head Agent

### Schéma (bloc de droite)

```
                HEAD AGENT
                (Orchestrateur)
                      |
        PARALLÈLE     |
   AGENT 1         AGENT 2
Recherche        Officielles
   Générale
                      |
        PARALLÈLE     |
                  AGENT 3
                (synthèse)
                      |
        SÉQUENTIEL    |
   AGENT 1         AGENT 2
Recherche        Officielles
                      |
        SÉQUENTIEL
                AGENT 3 Synthèse
              (APRÈS AGENT 1 et 2)
```

> Note OCR : certains libellés du schéma sont de petite taille / partiellement
> lisibles sur la capture (ex. la ligne "Pas (de) PRO spawner..." est une
> meilleure estimation du texte source, probablement "Pas le droit de spawner
> d'autres sous-agents").

---

## Résumé du schéma

Le schéma illustre l'**architecture agentique de Claude Code**, c'est-à-dire
comment un agent principal ("Head Agent" / orchestrateur) délègue du travail à
des sous-agents via le **Task tool**.

Points clés :

1. **Isolation des sous-agents** : chaque sous-agent dispose de son propre
   contexte (mémoire/historique séparée) et de ses propres outils autorisés.
   Il ne peut pas lui-même créer d'autres sous-agents (pas de récursion), et il
   renvoie uniquement un résultat texte unique au Head Agent qui l'a invoqué.

2. **Trois modes d'orchestration possibles** :
   - **Parallèle** : le Head Agent lance plusieurs sous-agents en même temps
     (jusqu'à ~7 simultanément) pour des recherches/tâches indépendantes
     (ex. Agent 1 "Recherche Générale" et Agent 2 "Sources Officielles"
     tournent en même temps), puis un Agent 3 fait la synthèse des résultats.
   - **Séquentiel (Pipeline)** : les agents s'exécutent les uns après les
     autres, chaque agent démarrant seulement quand le précédent a fini et
     transmis son résultat (Agent A → résultat → Agent B).
   - **Hybride (Fan-Out puis Pipeline)** : combinaison des deux — plusieurs
     agents tournent d'abord en parallèle (fan-out), puis leurs résultats sont
     consolidés séquentiellement par un agent final (Agent C), comme représenté
     dans le schéma de droite avec Agent 1 + Agent 2 en parallèle suivis d'un
     Agent 3 de synthèse.

3. **Principe général** : un seul sous-agent traite une tâche donnée, puis
   renvoie son résultat (texte) au Head Agent, qui orchestre l'ensemble et
   décide de la suite (autre agent, synthèse, ou réponse finale à
   l'utilisateur).

En résumé, le diagramme explique le mécanisme de délégation de Claude Code
pour les tâches complexes : un orchestrateur central distribue le travail à des
sous-agents spécialisés et isolés, selon trois patterns d'exécution
(parallèle, séquentiel, hybride), afin de paralléliser la recherche/le travail
tout en gardant une synthèse centralisée.
