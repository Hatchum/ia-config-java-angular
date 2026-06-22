)# 🧠 Claude Code — Roadmap d'optimisation

> **Objectif** : Mettre en place une configuration Claude Code la plus optimisée et propre possible, en suivant les meilleures pratiques officielles d'Anthropic.
>
> 📖 Docs officielles : [code.claude.com/docs](https://code.claude.com/docs/en/best-practices) | [Extend Claude Code](https://code.claude.com/docs/en/features-overview)

---

## Table des matières

1. [Fondation — CLAUDE.md](#1-fondation--claudemd)
2. [Rules — `.claude/rules/`](#2-rules--clauderules)
3. [Skills — `.claude/skills/`](#3-skills--claudeskills)
4. [Subagents — `.claude/agents/`](#4-subagents--claudeagents)
5. [Hooks — `.claude/settings.json`](#5-hooks--claudesettingsjson)
6. [MCP — Connexions externes](#6-mcp--connexions-externes)
7. [LSP — Code Intelligence](#7-lsp--code-intelligence)
8. [Workflows](#8-workflows)
9. [Gestion du contexte & sessions](#9-gestion-du-contexte--sessions)
10. [Modèles — Choix stratégique](#10-modèles--choix-stratégique)
11. [Automatisation & scaling](#11-automatisation--scaling)

---

## 1. Fondation — CLAUDE.md

> 📖 [Docs officielles CLAUDE.md](https://code.claude.com/docs/en/memory)

**Le fichier CLAUDE.md est lu automatiquement à chaque session.** C'est la base de tout.

### Hiérarchie des fichiers

| Emplacement | Portée | Usage |
|---|---|---|
| `~/.claude/CLAUDE.md` | Global (toutes sessions) | Conventions personnelles universelles |
| `./CLAUDE.md` | Projet (versionné git) | Conventions d'équipe, commandes build |
| `./CLAUDE.local.md` | Projet perso (dans `.gitignore`) | Overrides personnels non partagés |
| `./src/CLAUDE.md` | Sous-dossier | Chargé à la demande quand Claude travaille dans ce répertoire |

### Ce qu'il faut inclure / exclure

| ✅ Inclure | ❌ Exclure |
|---|---|
| Commandes Bash que Claude ne peut pas deviner | Ce que Claude peut déduire du code |
| Conventions de style différentes des défauts | Conventions standard du langage |
| Instructions de test et test runners | Documentation d'API détaillée (mettre un lien) |
| Conventions git (branches, PR) | Informations changeant fréquemment |
| Décisions d'architecture spécifiques au projet | Descriptions fichier par fichier |
| Quirks de l'environnement dev (env vars requises) | Pratiques évidentes comme "écrire du code propre" |

### Règles d'or

- **Garder CLAUDE.md sous 200 lignes** — au-delà, Claude commence à ignorer des règles
- Utiliser `@path/to/import` pour importer d'autres fichiers depuis CLAUDE.md
- Pour chaque ligne, se demander : *"Sa suppression ferait-elle faire des erreurs à Claude ?"* Si non → supprimer
- Versionner dans git pour que toute l'équipe contribue
- Utiliser `IMPORTANT:` ou `YOU MUST` pour les règles critiques

### Skills à créer

- [ ] **`skill-claude-memory`** : Skill qui recherche la documentation officielle sur la création/optimisation des fichiers CLAUDE.md, hiérarchie, path-scoped rules, best practices et anti-patterns. Déclencher quand on travaille avec CLAUDE.md ou `.claude/rules/`.
https://github.com/thedotmack/claude-mem/blob/main/docs/i18n/README.fr.md
---

## 2. Rules — `.claude/rules/`

> 📖 [Docs officielles Rules](https://code.claude.com/docs/en/memory#organize-rules-with-clauderules)

Les rules permettent de **découper CLAUDE.md en fichiers modulaires**, notamment pour du **path-scoping** (règles actives uniquement sur certains fichiers).

```
.claude/
  rules/
    java-conventions.md      # Actif uniquement sur les fichiers Java
    angular-conventions.md   # Actif uniquement sur les composants Angular
    test-conventions.md      # Actif uniquement sur les fichiers de test
```

**Frontmatter de path-scoping :**
```markdown
---
paths:
  - "**/*.java"
  - "src/main/**"
---
# Conventions Java
...
```

**Avantage clé** : Les règles path-scopées ne consomment du contexte que lorsque Claude travaille sur des fichiers correspondants → économie de tokens.

---

## 3. Skills — `.claude/skills/`

> 📖 [Docs officielles Skills](https://code.claude.com/docs/en/skills)

Les skills sont l'extension la plus flexible. Un skill est un fichier Markdown contenant connaissance, workflows ou instructions. Claude les charge à la demande, sans alourdir chaque session.


### Structure d'un skill

```markdown
.claude/skills/mon-skill/SKILL.md

---
name: mon-skill
description: Description précise pour que Claude sache quand l'utiliser
disable-model-invocation: true  # Optionnel : empêche Claude de l'auto-invoquer
---

# Contenu du skill
...
```

```markdown
---
name: [nom-court]
description: Utilise cette skill pour [cas d’usage précis], quand l’utilisateur demande [type de tâche] à partir de [type d’entrée].
---

# [Nom lisible de la skill]

## Objectif
[Décrire le résultat attendu en une phrase claire.]

## Quand utiliser cette skill
Utiliser cette skill si :
- [cas 1]
- [cas 2]
- [cas 3]

## Quand ne pas utiliser cette skill
Ne pas utiliser cette skill si :
- [cas hors périmètre 1]
- [cas hors périmètre 2]
- [cas hors périmètre 3]

## Entrées nécessaires
- [entrée 1]
- [entrée 2]
- [entrée 3]

## Ressources disponibles
Utiliser les ressources suivantes si elles existent :
- `references/` pour les règles métier.
- `templates/` pour les formats.
- `examples/` pour les exemples.
- `scripts/` pour les calculs ou transformations.
- `assets/` pour les éléments visuels.
- `tests/` pour les cas de vérification.

## Procédure
1. [Action 1]
2. [Action 2]
3. [Action 3]
4. [Action 4]
5. [Action 5]

## Contraintes
- [Contrainte 1]
- [Contrainte 2]
- [Contrainte 3]

## Validation humaine
Demander validation humaine si :
- [cas sensible 1]
- [cas sensible 2]
- [cas sensible 3]

Si validation humaine nécessaire :
1. Ne pas exécuter l’action finale.
2. Préparer un brouillon.
3. Lister les risques.
4. Lister les points à valider.

## Format de sortie

``markdown
## Analyse
- Objectif :
- Entrées utilisées :
- Données manquantes :
- Risques :

## Résultat
[Sortie principale]

## Points à valider
- [Point 1]
- [Point 2]
...
```

skill/
├── SKILL.md // Instruction principale
├── memory.md // Mémoire essentielle
├── references/ // Ce dossier contient les documents de référence, Règles métier. Utilisation :règles métier ; procédures internes ; politiques d’entreprise ;documentation ;normes ;définitions.
│   ├── regles-prompt-engineering.md
│   ├── criteres-reussite.md
│   └── limites-ia-generative.md
├── templates/ // Ce dossier contient les Formats de sortie. Utilisation :e-mails ;rapports ;devis ;tableaux ;scripts ;présentations ;comptes rendus.
│   ├── prompt-structure.xml
│   ├── audit-table.md
│   └── rapport-correction.md
├── examples/ // Ce dossier contient des exemples, Few-shots et cas types. Utilisation :stabiliser la sortie ;montrer le format ;éviter les erreurs ;guider le style.
│   ├── prompt-vague.md
│   ├── prompt-corrige.md
│   ├── demande-impossible.md
│   └── cas-validation-humaine.md
├── scripts/ // Ce dossier contient du code, Exécution déterministe. Utilisation : calculs ; vérifications ; transformations ; exports ; génération de fichiers ; contrôles déterministes. Une IA ne doit pas inventer une formule critique.
│   ├── extract_csv.py
│   ├── clean_data.py
│   ├── generate_report.py
│   └── validate_json.py
├── assets/ // Ce dossier contient les éléments non textuels. Utilisation : logos ; images ; chartes graphiques ; modèles visuels ; icônes.
│   ├── logo.png
│   ├── charte-couleur.pdf
│   ├── icones/
│   └── modele-slide.png
└── tests/ Ce dossier contient les cas de test, Vérification de fiabilité. Utilisation : vérifier la skill ; repérer les erreurs ; contrôler les régressions ; améliorer les règles.
	├── test-simple.md
	├── test-complexe.md
	├── test-donnees-manquantes.md
	└── test-hors-perimetre.md

### Skills à créer

#### `prompt-creator`
**But** : Meta-prompting — créer des prompts optimisés à partir des meilleures pratiques Anthropic, OpenAI, Google.
- Recherche sur internet les techniques de prompting des grandes IA
- Génère des prompts optimisés à partir des paramètres utilisateur
- Sources : [Anthropic Prompt Engineering](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview)

##### Procédure
1. Lire la demande utilisateur.
2. Identifier l’objectif réel.
3. Identifier les données nécessaires.
4. Vérifier si les données sont fournies.
5. Repérer les termes vagues.
6. Remplacer les termes vagues par des variables.
7. Définir les contraintes.
8. Définir le format de sortie.
9. Ajouter les critères de réussite.
10. Produire le prompt corrigé.

```markdown
Objectif : transformer une compétence métier en skill IA réutilisable.

Contexte :
La skill doit être utilisée dans un environnement IA capable de lire une instruction structurée.
La skill doit réduire l’improvisation.
La skill doit suivre une procédure claire.
La skill doit prévoir les cas de validation humaine.

Compétence à transformer :
[COLLER LA COMPÉTENCE]

Public cible :
[COLLER LE PUBLIC]

Tâche principale :
[COLLER LA TÂCHE]

Entrées disponibles :
[LISTE DES DONNÉES DISPONIBLES]

Outils disponibles :
[LISTE DES OUTILS OU ÉCRIRE "AUCUN OUTIL"]

Ressources disponibles :
[LISTE DES RESSOURCES OU ÉCRIRE "AUCUNE RESSOURCE"]

Procédure :
1. Identifier l’objectif réel de la skill.
2. Définir le nom court de la skill.
3. Rédiger une description de déclenchement.
4. Définir quand utiliser la skill.
5. Définir quand ne pas utiliser la skill.
6. Lister les entrées nécessaires.
7. Construire une SOP en étapes courtes.
8. Ajouter les contraintes.
9. Ajouter les cas de validation humaine.
10. Définir le format de sortie.
11. Ajouter trois exemples d’usage.
12. Ajouter une checklist de test.

Contraintes :
- Ne pas utiliser de rôle vague.
- Ne pas commencer par "Tu es".
- Utiliser des phrases courtes.
- Une étape doit contenir une seule action.
- Ne pas inventer de ressource.
- Ne pas supposer qu’un outil existe.
- Signaler les limites.
- Prévoir les données manquantes.

Format de sortie :
Produire un fichier SKILL.md complet en Markdown.

Structure attendue :
---
name:
description:
---

# [Nom de la skill]

## Objectif
## Quand utiliser cette skill
## Quand ne pas utiliser cette skill
## Entrées nécessaires
## Ressources disponibles
## Procédure
## Contraintes
## Validation humaine
## Format de sortie
## Exemples
## Checklist de test
...
```

#### audit 
vérifier si une skill est fiable.
```markdown
Objectif : auditer une skill IA et identifier les risques de mauvaise exécution.

Skill à auditer :
[COLLER LE CONTENU DE LA SKILL]

Procédure :
1. Identifier l’objectif de la skill.
2. Vérifier si l’objectif est clair.
3. Vérifier si la description permet un bon déclenchement.
4. Vérifier si les cas de non-utilisation sont présents.
5. Vérifier si les entrées nécessaires sont listées.
6. Vérifier si la procédure est assez précise.
7. Vérifier si les contraintes sont explicites.
8. Vérifier si les cas de validation humaine sont présents.
9. Vérifier si le format de sortie est exploitable.
10. Identifier les risques d’invention.
11. Identifier les risques d’action non autorisée.
12. Proposer une version corrigée.

Contraintes :
- Ne pas réécrire inutilement toute la skill.
- Corriger seulement ce qui améliore la fiabilité.
- Signaler les points critiques en priorité.

Format :
Tableau Markdown avec colonnes :
- Élément audité
- Problème détecté
- Niveau de risque
- Correction proposée

Puis :
## Version corrigée
[SKILL.md amélioré]
...
```

Une skill doit être testée sur des cas normaux, complexes, incomplets, hors périmètre et sensibles.
```markdown
Objectif : créer une suite de tests pour vérifier la fiabilité d’une skill IA.

Skill à tester :
[COLLER LA SKILL]

Procédure :
1. Identifier la tâche principale.
2. Créer un cas normal.
3. Créer un cas complexe.
4. Créer un cas avec données manquantes.
5. Créer un cas hors périmètre.
6. Créer un cas à risque.
7. Définir la sortie attendue pour chaque cas.
8. Définir les erreurs à surveiller.
9. Créer une grille d’évaluation.

Contraintes :
- Ne pas tester seulement les cas faciles.
- Inclure au moins un cas où la skill doit refuser ou demander validation.
- Les sorties attendues doivent être observables.

Format :
## Suite de tests

### Test 1 — Cas normal
- Entrée :
- Résultat attendu :
- Erreurs à surveiller :

### Test 2 — Cas complexe
- Entrée :
- Résultat attendu :
- Erreurs à surveiller :

### Test 3 — Données manquantes
- Entrée :
- Résultat attendu :
- Erreurs à surveiller :

### Test 4 — Hors périmètre
- Entrée :
- Résultat attendu :
- Erreurs à surveiller :

### Test 5 — Validation humaine
- Entrée :
- Résultat attendu :
- Erreurs à surveiller :

## Grille d’évaluation
| Critère | Réussi | Échec | Commentaire |
...
```


```markdown
Objectif : améliorer une skill à partir d’une erreur observée.

Skill actuelle :
[COLLER LA SKILL]

Erreur observée :
[DÉCRIRE L’ERREUR]

Sortie incorrecte :
[COLLER LA SORTIE]

Sortie attendue :
[DÉCRIRE LA SORTIE ATTENDUE]

Procédure :
1. Identifier la cause probable de l’erreur.
2. Classer la cause :
   - objectif flou ;
   - déclenchement mauvais ;
   - entrée manquante ;
   - procédure imprécise ;
   - contrainte absente ;
   - exemple absent ;
   - format mal défini ;
   - validation humaine absente.
3. Proposer une correction minimale.
4. Modifier la skill.
5. Ajouter un test pour éviter la répétition de l’erreur.

Contraintes :
- Ne pas complexifier inutilement la skill.
- Corriger la cause racine.
- Ajouter une règle seulement si elle réduit le risque.

Format :
## Diagnostic
## Cause
## Correction minimale
## SKILL.md corrigé
## Nouveau test ajouté
...
```

création de memory
```markdown
Objectif : créer une mémoire minimale à partir d’une skill IA.

Skill :
[COLLER LA SKILL]

Procédure :
1. Extraire l’objectif.
2. Extraire les règles essentielles.
3. Extraire la procédure.
4. Extraire les contraintes.
5. Extraire les cas de validation humaine.
6. Extraire le format de sortie.
7. Supprimer les exemples longs.
8. Supprimer les répétitions.
9. Produire une mémoire courte et réutilisable.

Contraintes :
- Ne pas copier toute la skill.
- Ne pas ajouter d’information absente.
- Utiliser des phrases courtes.
- Garder uniquement ce qui sera utile pour une prochaine exécution.

Format :
# memory.md

## Sujet
## Objectif
## Règles essentielles
## Procédure
## Contraintes
## Validation humaine
## Format de sortie
## Erreurs à éviter
...
```

audit de prompt
```markdown
---
name: audit-prompt-objectif
description: Utilise cette skill pour auditer un prompt, supprimer les rôles vagues, clarifier l’objectif, ajouter les contraintes, définir le format et améliorer la fiabilité.
---

# Audit de prompt par objectif

## Objectif
Transformer un prompt vague en prompt structuré, fiable et exploitable.

## Quand utiliser cette skill
Utiliser cette skill si l’utilisateur demande :
- d’améliorer un prompt ;
- de corriger un prompt ;
- de rendre un prompt plus précis ;
- de transformer une demande vague en instruction ;
- de supprimer un rôle inutile ;
- de créer un prompt professionnel.

## Quand ne pas utiliser cette skill
Ne pas utiliser cette skill si :
- l’utilisateur demande seulement une reformulation stylistique ;
- le prompt contient une demande illégale ;
- les données nécessaires sont absentes et aucune hypothèse n’est autorisée ;
- la demande exige une action sans outil disponible.

## Entrées nécessaires
- Prompt original.
- Objectif réel si connu.
- Public cible si connu.
- Format attendu si connu.
- Contraintes métier si disponibles.

## Procédure
1. Lire le prompt original.
2. Identifier l’objectif réel.
3. Repérer les rôles vagues.
4. Supprimer les rôles inutiles.
5. Repérer les termes imprécis.
6. Remplacer les termes imprécis par des variables.
7. Identifier les données manquantes.
8. Identifier les outils nécessaires.
9. Ajouter les contraintes.
10. Ajouter le format de sortie.
11. Ajouter les critères de réussite.
12. Produire le prompt corrigé.

## Contraintes
- Ne pas commencer par "Tu es".
- Ne pas utiliser de rôle si l’objectif suffit.
- Ne pas inventer les données manquantes.
- Ne pas rendre réalisable une tâche impossible.
- Ne pas supprimer une contrainte métier importante.
- Utiliser des phrases courtes.
- Préférer les critères observables.

## Validation humaine
Demander validation humaine si :
- le prompt engage une décision juridique ;
- le prompt engage une décision financière ;
- le prompt touche à la santé ;
- le prompt implique une action irréversible ;
- le prompt doit être utilisé en production.

## Format de sortie

``markdown
## Diagnostic
- Objectif réel :
- Problèmes détectés :
- Données manquantes :
- Risques :

## Prompt corrigé
[Prompt structuré]

## Critères de réussite
- Critère 1
- Critère 2
- Critère 3
...
```

```markdown
# memory.md — Synthèse globale

## Sujet
SKILL Prompt Engineering avancé.

## Définition
Une skill IA est une compétence structurée, réutilisable et testable.

## Principe central
Structurer par objectif.  
Ne pas structurer par rôle vague.

## Structure essentielle
Métadonnées → Objectif → Déclenchement → Entrées → SOP → Contraintes → Validation humaine → Format → Exemples → Tests.

## Règles principales
- Commencer par l’objectif.
- Écrire des phrases courtes.
- Définir quand utiliser la skill.
- Définir quand ne pas l’utiliser.
- Lister les entrées nécessaires.
- Décomposer la procédure.
- Ajouter les contraintes.
- Prévoir la validation humaine.
- Définir le format de sortie.
- Tester les cas simples, complexes, incomplets, hors périmètre et sensibles.

## Limites
Une skill ne donne pas accès automatiquement aux données à jour.  
Une skill ne vérifie pas seule les faits.  
Une skill ne doit pas inventer les données manquantes.  
Une skill ne doit pas exécuter d’action sensible sans validation.

## Usage professionnel
Une skill permet de transformer une expertise métier en actif réutilisable.  
Elle peut être utilisée pour former, automatiser, standardiser et déléguer des tâches à une IA.

## Critère de réussite
Une skill est réussie si elle produit un résultat stable, contrôlable, exploitable et conforme aux limites définies.
...
```


#### `skill-claude-memory`
**But** : Documenter la création et l'optimisation des fichiers CLAUDE.md.
- Recherche la documentation officielle Claude Code sur CLAUDE.md
- Guide sur la hiérarchie, structure, path-scoped rules, best practices, anti-patterns
- Déclencher quand on travaille avec CLAUDE.md ou `.claude/rules/`

#### `skill-subagent-creator`
**But** : Guider la création de subagents optimisés.
- Template de subagent avec frontmatter complet
- Bonnes pratiques d'isolation de contexte
- Choix du modèle selon la tâche

#### `skill-workflow-creator`
**But** : Créer des workflows EPCT (Explore / Plan / Code / Test) avec étapes séparées.
- Chaque étape dans un fichier distinct pour forcer Claude à lire séquentiellement
- Voir section [Workflows](#8-workflows) pour le détail

#### `skill-hook-creator`
**But** : Guider la création de hooks Claude Code.
- Templates pour chaque type de hook (PreToolUse, PostToolUse, Stop, etc.)
- Patterns de validation (syntaxe TS, Java, etc.)
- Lien vers [Docs Hooks](https://code.claude.com/docs/en/hooks-guide)

### Skills bundlés disponibles (à connaître)

Claude Code inclut nativement : `/code-review`, `/batch`, `/debug`, `/loop`, `/claude-api`

### Règles d'or des skills

- **Description précise et distinctive** → Claude s'en sert pour décider quand charger le skill
- Les descriptions chargent à chaque session (faible coût) ; le contenu complet uniquement à l'invocation
- `disable-model-invocation: true` → le skill ne se charge que si vous le demandez explicitement (coût contexte = 0)
- Un skill peut lancer des subagents avec `context: fork`
- Installer des skills communautaires : [skills.sh](https://www.skills.sh)

---

## 4. Subagents — `.claude/agents/`

> 📖 [Docs officielles Subagents](https://code.claude.com/docs/en/sub-agents)

Les subagents tournent dans leur **propre fenêtre de contexte** et ne retournent qu'un résumé à la session principale. Idéal pour les tâches qui lisent beaucoup de fichiers ou nécessitent une spécialisation.
Ne necessite pas la totalité du contexte pour fonctionner. Ne donne qu'une synthèse necessaire à l'agent orchestrateur pour continuer le workflow.

### Structure d'un subagent

```markdown
.claude/agents/mon-agent.md

---
name: mon-agent
description: Description précise de ce que fait cet agent
tools: Read, Grep, Glob, Bash
model: haiku          # haiku / sonnet / opus selon la complexité
permissionMode: auto  # auto / plan / default
skills:
  - mon-skill         # Skills préchargés au lancement
maxTurns: 20
---

Prompt système de l'agent...
```

### Subagents à créer

#### `agent-explore-docs`
**But** : Recherche la documentation officielle d'une librairie/fonctionnalité.
- **Modèle** : `haiku` (tâche rapide, recherche simple)
- **Tools** : `Read`, `Bash`, `WebFetch`, MCP Context7
- **MCP** : Context7 (documentation de librairies)
- **Usage** : `"Use agent-explore-docs to find React Router v7 documentation on nested routes"`

#### `agent-explore-web`
**But** : Recherche web généraliste.
- **Modèle** : `haiku`
- **Tools** : `WebSearch`, `WebFetch`, MCP Exa
- **Usage** : Veille technologique, recherche de solutions

#### `agent-explore-code`
**But** : Explore le code du projet sans polluer le contexte principal.
- **Modèle** : `haiku`
- **Tools** : `Read`, `Grep`, `Glob`
- **Usage** : Compréhension d'une base de code inconnue, recherche de patterns

#### `agent-security-reviewer`
**But** : Revue de sécurité en contexte isolé.
- **Modèle** : `opus` (analyse de sécurité, précision critique)
- **Tools** : `Read`, `Grep`, `Glob`, `Bash`

#### `agent-code-java`
**But** : Implémentation Java avec focus sur les couches.
- **Modèle** : `sonnet`
- **Skills** : `java-conventions`, `spring-patterns`
- *Envisager de diversifier par couche : controller / service / repository*

#### `agent-code-angular`
**But** : Implémentation Angular.
- **Modèle** : `sonnet`
- **Skills** : `angular-conventions`
- *Envisager de diversifier : component / service / routing / state*

### Quand utiliser subagent vs agent team

| Critère | Subagent | Agent Team |
|---|---|---|
| Contexte | Isolé, retourne un résumé | Indépendant, communication peer-to-peer |
| Coordination | Agent principal gère tout | Auto-coordination avec liste de tâches partagée |
| Coût tokens | Faible (résumé uniquement) | Élevé (chaque agent = instance Claude séparée) |
| Idéal pour | Tâche focalisée, résultat seul compte | Travail complexe, recherche avec hypothèses concurrentes |

> ⚠️ Agent Teams = feature expérimentale, désactivée par défaut.

---

## 5. Hooks — `.claude/settings.json`

> 📖 [Docs officielles Hooks](https://code.claude.com/docs/en/hooks-guide) | [Référence Hooks](https://code.claude.com/docs/en/hooks)

Les hooks sont **déterministes** : contrairement aux instructions CLAUDE.md (advisory), un hook **garantit** l'exécution d'une action. Configurer via `/hooks` ou directement dans `.claude/settings.json`.

### Événements disponibles

| Événement | Quand | Usage typique |
|---|---|---|
| `PreToolUse` | Avant l'exécution d'un outil | Validation, blocage de commandes dangereuses |
| `PostToolUse` | Après l'exécution d'un outil | Linting, formatage, logging |
| `SessionStart` | Démarrage d'une session | Setup de l'environnement |
| `Stop` | Fin d'une session | Nettoyage, notifications |

### Types de hooks

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "eslint --fix $FILE && tsc --noEmit"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/security-check.sh"
          }
        ]
      }
    ]
  }
}
```

### Hooks à créer

- [ ] **Validation syntaxe TypeScript** : `PostToolUse` sur Edit → `tsc --noEmit`
- [ ] **Validation syntaxe Java** : `PostToolUse` sur Edit → `javac` ou build tool
- [ ] **Blocage migrations** : `PreToolUse` sur Write → bloquer les écritures dans le dossier migrations
- [ ] **ESLint/Prettier** : `PostToolUse` sur Edit → auto-formatage

> 💡 **Règle clé** : "Ne jamais modifier `.env`" dans CLAUDE.md est une *requête*. Un hook `PreToolUse` qui bloque l'édition est une *garantie*.

---

## 6. MCP — Connexions externes (REMOVED)

> 📖 [Docs officielles MCP](https://code.claude.com/docs/en/mcp)

Les MCP servers connectent Claude à des services externes. Ajouter via `claude mcp add`.

### MCP à intégrer

| MCP | Utilité | Modèle recommandé | Priorité |
|---|---|---|---|
| **Context7** | Documentation officielle de librairies en temps réel | `haiku` (via agent-explore-docs) | 🔴 Haute |
| **Exa** (payant) | Recherche web sémantique avancée | `haiku` (via agent-explore-web) | 🟡 Moyenne |

### Commandes utiles

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
claude mcp list
/mcp   # Voir statut et coût tokens par serveur dans la session
```

### Bonnes pratiques MCP

- Utiliser `/permissions` pour ajouter des domaines fréquemment utilisés à la liste blanche
- Déconnecter les serveurs MCP non utilisés pour économiser du contexte
- Les noms d'outils MCP se chargent au démarrage ; les schémas complets sont différés

---

## 6.b. CLI + skill (REPLACE MCP)

### CLI à intégrer

| Nom | Utilité | Modèle recommandé | Priorité | CLI |
|---|---|---|---|
| **Context7** | Documentation officielle de librairies en temps réel | `haiku` (via agent-explore-docs) | 🔴 Haute | npx ctx7 setup --claude |
| **Exa** (payant) | Recherche web sémantique avancée | `haiku` (via agent-explore-web) | 🟡 Moyenne | ??? |

---

## 7. LSP — Code Intelligence

> 📖 [Docs officielles LSP / Code Intelligence](https://code.claude.com/docs/en/tools-reference#lsp-tool-behavior)

Le LSP donne à Claude une **navigation au niveau des symboles** et des **erreurs de type en temps réel**, remplaçant grep/glob pour le code typé.

### Installation

#### Java
```bash
brew install jdtls
claude plugin install jdtls-lsp@claude-plugins-official
```

#### TypeScript
```bash
npm i -g typescript-language-server typescript
claude plugin install typescript-lsp@claude-plugins-official
```

#### Vérification
```bash
claude plugin list
```

### Configuration `~/.claude/settings.json`

```json
{
  "env": {
    "ENABLE_LSP_TOOL": "1"
  },
  "enabledPlugins": {
    "jdtls-lsp@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true
  }
}
```

### Règles LSP dans `~/.claude/CLAUDE.md`

```markdown
### Code Intelligence — Préférer LSP à Grep/Glob/Read

- `goToDefinition` / `goToImplementation` → aller à la source
- `findReferences` → trouver tous les usages dans le projet
- `workspaceSymbol` → localiser une définition
- `documentSymbol` → lister tous les symboles d'un fichier
- `hover` → infos de type sans lire le fichier
- `incomingCalls` / `outgoingCalls` → hiérarchie des appels

Avant de renommer ou modifier une signature de fonction : `findReferences` d'abord.
Utiliser Grep/Glob uniquement pour les recherches textuelles (commentaires, strings, config).
Après toute modification : vérifier les diagnostics LSP avant de continuer.
```

---

## 8. Workflows

> 📖 [Docs officielles — Workflow EPCT](https://code.claude.com/docs/en/best-practices#explore-first-then-plan-then-code)

### Principe : Séparer exploration et implémentation

Les workflows sont stockés dans des **fichiers distincts** pour que Claude lise chaque étape séquentiellement, évitant de charger trop de contexte d'un coup.

```
.claude/skills/
  workflow-dev/
    SKILL.md          # Point d'entrée, description du workflow
    step-0-init.md
    step-1-explore.md
    step-2-plan.md
    step-3-code.md
    step-4-test.md
  workflow-debug/
    SKILL.md
    step-0-init.md
    step-1-analyze.md
    step-1b-log-instrumentation.md  # Optionnel
    step-2-find-solutions.md
    step-3-propose.md
    step-4-fix.md
    step-5-verify.md
    _reference-log-technique.md     # Patterns de logs, préfixes, sécurité
```

### Workflow DEV — EPCT

```
E(xplore) → P(lan) → C(ode) → T(est)
```

**Step 0 — Init** : Parsing des flags, setup de l'état initial
**Step 1 — Explore** : Utiliser les subagents explore (code, docs, web) en mode Plan (lecture seule)
**Step 2 — Plan** : Créer un plan d'implémentation détaillé → éditer avec `Ctrl+G` avant de valider
**Step 3 — Code** : Implémenter en suivant le plan, avec logging stratégique
**Step 4 — Test** : Vérification multi-couches (Static → Build → Runtime → User)

### Workflow DEBUG

**Principe clé** : Tests qui passent ≠ fix qui fonctionne. Toujours exécuter le vrai chemin de code.

**Technique de Log** : Quand l'erreur ne peut pas être reproduite, ajouter des logs de debug stratégiques → l'utilisateur exécute et partage la sortie console.

| Étape | Action | Point de validation utilisateur |
|---|---|---|
| 0 — Init | Parser les flags, setup état | — |
| 1 — Analyze | Reproduire l'erreur, identifier la cause racine | **Demander si vous avez plus de contexte** |
| 1b — Log Instrumentation | Ajouter des logs de debug *(optionnel)* | **L'utilisateur exécute et partage la sortie** |
| 2 — Find Solutions | Rechercher 2-3+ solutions avec pros/cons | — |
| 3 — Propose | Présenter les options | **Vous choisissez la solution** |
| 4 — Fix | Implémenter avec logging stratégique | — |
| 5 — Verify | Vérification multi-couches | **Confirmation utilisateur** |

---

## 9. Gestion du contexte & sessions

> 📖 [Docs officielles — Context Management](https://code.claude.com/docs/en/best-practices#manage-your-session)

**La fenêtre de contexte est la ressource la plus critique.** Les performances dégradent quand elle se remplit.

### Commandes essentielles

| Commande | Usage |
|---|---|
| `/clear` | Réinitialiser le contexte entre tâches non liées |
| `/compact <focus>` | Compacter avec instructions : `/compact Focus sur les changements API` |
| `/rewind` | Ouvrir le menu rewind pour restaurer état conversation/code |
| `Ctrl+G` | Ouvrir le plan dans l'éditeur texte pour édition directe |
| `Esc` | Stopper Claude en cours (contexte préservé) |
| `Esc + Esc` | Ouvrir le menu rewind |
| `/btw` | Questions rapides sans polluer le contexte (overlay dismissible) |
| `/rename` | Nommer une session pour la retrouver (`claude --resume`) |

### Anti-patterns à éviter

| Anti-pattern | Symptôme | Fix |
|---|---|---|
| **Session fourre-tout** | Tâches non liées mélangées | `/clear` entre chaque tâche |
| **Corrections répétées** | Claude fait la même erreur × 2 | `/clear` + réécrire le prompt avec ce qu'on a appris |
| **CLAUDE.md surchargé** | > 200 lignes, règles ignorées | Pruner sans pitié → déplacer vers skills |
| **Exploration infinie** | Claude lit des centaines de fichiers | Déléguer à un subagent + scope précis |
| **Trust-then-verify gap** | Implémentation sans vérification | Fournir tests/scripts de vérification |

### Cache et déclencheurs de cache mort

Le cache est **activé par défaut**. Il se réinitialise si :
- Changement de modèle
- Ajout d'un MCP
- Délai > 5 minutes sans activité

### Coût contexte des fichiers

| Coût relatif | Types de fichiers |
|---|---|
| 1x | `.txt`, `.md` |
| 5x | `.pdf`, `.doc` |
| 20x | Images, screenshots |

---

## 10. Modèles — Choix stratégique

| Modèle | Usage | Tâches |
|---|---|---|
| **Opus** | Architecture, structuration, réflexion profonde | Tâches complexes, raisonnement, sécurité |
| **Sonnet** | Code, écriture, exécution | Tâches modérées, implémentation |
| **Haiku** | Recherche, classification, exploration | Tâches simples/rapides, subagents explore |

**Règle pratique** :
- Agents explore → **Haiku** (rapide, peu cher)
- Agents code → **Sonnet** (équilibre performance/coût)
- Reviews sécurité, architecture → **Opus** (précision maximale)

---

## 11. Automatisation & scaling

> 📖 [Docs officielles — Automate and Scale](https://code.claude.com/docs/en/best-practices#automate-and-scale)

### Mode non-interactif (CI/Scripts)

```bash
# Requête ponctuelle
claude -p "Expliquer ce que fait ce projet"

# Sortie structurée pour scripts
claude -p "Lister tous les endpoints API" --output-format json

# Mode auto pour CI (classifier de sécurité intégré)
claude --permission-mode auto -p "fix all lint errors"

# Pipeline
claude -p "Analyser ce log" --output-format stream-json --verbose | votre_commande
```

### Agent Teams (expérimental)

> ⚠️ Désactivé par défaut — activer dans les settings.

Pattern Writer/Reviewer :
- **Session A** : Implémenter
- **Session B** : Reviewer en contexte frais (pas de biais vers le code qu'elle vient d'écrire)

### Fan-out sur des fichiers en masse

```bash
for file in $(cat files.txt); do
  claude -p "Migrer $file de React à Vue. Retourner OK ou FAIL." \
    --allowedTools "Edit,Bash(git commit *)"
done
```

### Commandes session

```bash
claude --continue   # Reprendre la session la plus récente
claude --resume     # Choisir dans la liste des sessions
```

---

## Récapitulatif — Ordre d'implémentation recommandé

```
Phase 1 — Base (Immédiat)
├── ~/.claude/CLAUDE.md (global)         ← conventions personnelles
├── ./CLAUDE.md (projet)                  ← conventions d'équipe
├── LSP TypeScript + Java                 ← code intelligence
└── /init sur chaque projet               ← CLAUDE.md auto-généré

Phase 2 — Extensions (Court terme)
├── .claude/rules/                        ← règles path-scopées
├── .claude/skills/skill-claude-memory/   ← documentation CLAUDE.md
├── .claude/skills/skill-prompt-creator/  ← meta-prompting
├── .claude/skills/skill-hook-creator/    ← création de hooks
└── Hooks de validation (TS, Java)        ← qualité automatique

Phase 3 — Subagents & Workflows (Moyen terme)
├── .claude/agents/agent-explore-docs/    ← doc de librairies
├── .claude/agents/agent-explore-code/    ← exploration codebase
├── .claude/agents/agent-explore-web/     ← recherche web
├── .claude/skills/workflow-dev/          ← EPCT workflow
├── .claude/skills/workflow-debug/        ← debug workflow
└── MCP Context7                          ← doc en temps réel

Phase 4 — Spécialisation (Long terme)
├── .claude/agents/agent-code-java/       ← implémentation Java
├── .claude/agents/agent-code-angular/    ← implémentation Angular
├── .claude/agents/agent-security-reviewer/
├── MCP Exa (payant)                      ← recherche web avancée
└── Agent Teams (expérimental)            ← orchestration avancée
```

---

## Ressources officielles

- [Best Practices](https://code.claude.com/docs/en/best-practices)
- [Extend Claude Code](https://code.claude.com/docs/en/features-overview)
- [CLAUDE.md / Memory](https://code.claude.com/docs/en/memory)
- [Skills](https://code.claude.com/docs/en/skills)
- [Subagents](https://code.claude.com/docs/en/sub-agents)
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Hooks Reference](https://code.claude.com/docs/en/hooks)
- [MCP](https://code.claude.com/docs/en/mcp)
- [Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Discover Plugins](https://code.claude.com/docs/en/discover-plugins)
- [Community Skills](https://www.skills.sh)
