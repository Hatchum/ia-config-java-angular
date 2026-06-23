# Structure agentique pour le développement de features Java/Angular

> Source vérifiée : [Subagents](https://code.claude.com/docs/en/sub-agents) ·
> [Skills](https://code.claude.com/docs/en/skills) ·
> [Dynamic workflows](https://code.claude.com/docs/en/workflows) ·
> [Agent teams](https://code.claude.com/docs/en/agent-teams) ·
> [Best practices](https://code.claude.com/docs/en/best-practices) ·
> Vérifié le 2026-06-23 (workflows/agent-teams = nouvelle lecture ; le reste
> reprend les fiches `docs/reference/*.md` déjà vérifiées le 2026-06-22).
> Généré à partir de `prompt-structure-agentique.md` (skill `prompt-creator`).

## Contexte

Ce document répond à la demande : « mettre en place une structure agentique
pour le développement de features dans une application Java/Angular », avec
exigence explicite que **ni le workflow ni le jeu de subagents ne soient figés**
— le système doit rester paramétrable sur ces deux axes. Il fait avancer le
backlog **Phase 3/4** de [`roadmap.md`](../guide/roadmap.md) (« Subagents &
Workflows » / « Spécialisation ») et le chantier **« Subagents »** marqué
❌ dans [`architecture-biagent.md` §11](architecture-biagent.md). Rien ici ne
remplace ces fichiers : ce document **séquence et complète** leur backlog, il
ne le duplique pas.

## Inventaire (existant vs nouveau)

| Brique | État | Référence |
|---|---|---|
| Instructions projet (`AGENTS.md` → `CLAUDE.md`) | ✅ en place | `AGENTS.md`, `CLAUDE.md` |
| Règles de convention Java/Angular | ✅ en place | `.ai/rules/java-coding-rules.md`, `.ai/rules/angular-coding-rules.md` |
| ~28 skills (Java, Angular, méta-outillage) | ✅ en place | `.ai/skills/*/SKILL.md` (liste ci-dessous) |
| Source de config résiduelle (permissions, hooks) + générateur | ✅ en place | `.ai/config/permissions.yaml`, `.ai/config/hooks.yaml`, `scripts/sync-config.py` |
| Subagents intégrés (Explore, Plan, general-purpose…) | ✅ disponibles nativement | `docs/reference/subagents.md` |
| Subagents projet (`agent-explore-*`, `agent-code-*`, `agent-security-reviewer`) | ❌ documentés, **pas encore créés** | `docs/reference/subagents.md` §« à créer » |
| `.ai/config/subagents.yaml` (source) + génération `.claude/agents/*.md` | ❌ pas encore créé | `architecture-biagent.md` §11 |
| Skills `workflow-dev` / `workflow-debug` (EPCT, DEBUG en fichiers-étapes) | ❌ pas encore créés | `docs/reference/skills.md`, `docs/reference/workflows.md` |
| Mécanisme de **dynamic workflows** natif (`/workflows`, scripts JS) | ✅ existe nativement côté Claude Code, ⚠️ **non exploité** par le kit | nouveau — voir §Workflows |
| Agent Teams (expérimental) | ✅ existe nativement, **désactivé par défaut** | `docs/reference/subagents.md`, nouveau §Workflows |
| Rôle abstrait « researcher / backend-coder / frontend-coder / reviewer » | ❌ n'existe pas encore | nouveau — voir §Rôles |
| Subagent de revue adverse léger (gate de fin de boucle) | ❌ n'existe pas | nouveau — voir §Subagents |

**Skills déjà présents** (réutilisables tels quels par les futurs subagents,
aucun n'est à recréer) :
Java — `java-code-review`, `jpa-patterns`, `spring-boot-patterns`, `test-quality`,
`concurrency-review`, `security-audit`, `maven-dependency-audit`, `java-migration`,
`performance-smell-detection`, `logging-patterns`, `clean-code`, `solid-principles`,
`design-patterns`, `architecture-review`, `api-contract-review`.
Angular — `angular-developer`, `angular-new-app`.
Outillage — `prompt-creator`, `skill-creator`, `subagent-creator`, `find-docs`,
`find-skills`, `playwright`, `api-testing`, `git-commit`, `issue-triage`,
`changelog-generator`, `firecrawl-deep-research`, `image-ocr`.

## Correction de fraîcheur — `docs/reference/workflows.md`

La note « Dynamic workflows / revue adverse » de `workflows.md` (ligne 84-91)
reste **directionnellement correcte** mais sous-décrit fortement le mécanisme
réel. Mise à jour, sans écraser le fichier existant (à reporter dans
`workflows.md` lors d'une prochaine passe) :

- Une *dynamic workflow* n'est pas un simple « outil `Workflow` » : c'est un
  **script JavaScript** que Claude écrit, exécuté par un runtime séparé en
  arrière-plan (jusqu'à 16 agents concurrents, 1000 agents/run max), pendant
  que la session reste utilisable.
- Elle se déclenche par le mot-clé `ultracode` dans le prompt (ou en demandant
  « run a workflow » en langage naturel), ou via `/effort ultracode` pour que
  Claude planifie un workflow à chaque tâche substantielle de la session.
- Un run réussi se **sauvegarde** comme commande slash réutilisable —
  `.claude/workflows/<nom>.js` (projet, partagé git) ou `~/.claude/workflows/`
  (perso) — et accepte un paramètre `args` à l'invocation (`/<nom> arg1 arg2`).
  **C'est le mécanisme natif de paramétrage de workflow** que ce document
  retient au §Rôles & paramétrage, plutôt que d'inventer un interpréteur.
- Requiert Claude Code **v2.1.154+** et un toggle explicite (`/config` →
  « Dynamic workflows », activé par défaut sur les plans payants) — à vérifier
  sur les postes de l'équipe avant d'en dépendre (voir §Questions ouvertes).
- Le skill bundlé `/deep-research` est un exemple livré en standard de ce
  mécanisme (recherche web multi-angles, sources contre-vérifiées entre
  agents).
- **Agent Teams** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) est un **troisième
  mécanisme**, distinct des subagents et des dynamic workflows : plusieurs
  **sessions** Claude Code indépendantes (pas des subagents) coordonnées par
  une session « lead », avec liste de tâches partagée et messagerie
  peer-to-peer directe entre coéquipiers. Point clé pour ce kit : une
  **définition de subagent existante peut être réutilisée comme rôle de
  coéquipier** (« Spawn a teammate using the security-reviewer agent type »),
  ce qui permet de définir un rôle une seule fois et de le faire servir dans
  les trois mécanismes (délégation directe, worker de dynamic workflow,
  coéquipier d'agent team).

## Workflows catalogue

Quatre patterns couvrent le cycle de vie feature/bug/revue ; aucun n'est
« le » workflow par défaut — voir §Rôles & paramétrage pour la sélection.

| Pattern | Archetype déclencheur | Étapes ordonnées | Gate(s) de vérification | Mécanisme porteur |
|---|---|---|---|---|
| **EPCT** | `feature` (scope clair à moyen) | Explore (plan mode, lecture seule) → Plan (éditable `Ctrl+G`) → Code → Commit | Tests/build verts avant commit ; preuve montrée, pas affirmée | Skill `workflow-dev` (fichiers-étapes), session unique |
| **DEBUG** | `bug-fix` | Analyze (repro + cause racine) → Log (optionnel) → Find (2-3+ solutions) → Propose (choix utilisateur) → Fix → Verify (multi-couches) | Validation utilisateur aux étapes 1, 3, 5 ; test de non-régression ajouté | Skill `workflow-debug` (fichiers-étapes), session unique |
| **Revue adverse / audit ciblé** | `review-refactor` sur diff/PR existant | Un subagent en contexte frais lit *uniquement* le diff + les critères → rapport d'écarts | Ne signale que les écarts affectant correction/exigences (sinon sur-ingénierie) | Subagent dédié (`agent-review-adversarial`), invocable seul ou en fin d'EPCT/DEBUG |
| **Audit/migration à grande échelle** | tâche dépassant ce qu'une session peut coordonner (audit multi-fichiers, migration de masse, recherche à sources croisées) | Script de dynamic workflow écrit par Claude → fan-out de workers (subagents projet réutilisés comme workers) → résultat consolidé | Le script peut faire **revoir adversairement** les résultats par des workers indépendants avant de les remonter | Dynamic workflow natif (`/workflows`, sauvegardable sous `.claude/workflows/`) |

> **Pattern volontairement non retenu en standard** : Agent Teams pour le
> développement courant — coût en tokens significativement plus élevé,
> expérimental, et la coordination peer-to-peer n'apporte rien sur des tâches
> séquentielles à fichiers non partagés (le cas dominant d'une feature
> Java/Angular). Conservé comme option pour les cas listés en §Questions
> ouvertes (hypothèses concurrentes en debug, revue PR multi-angles).

## Rôles & paramétrage

### Principe : une couche de rôles entre workflow et subagent

Chaque étape d'un workflow référence un **rôle abstrait**, jamais un nom de
subagent en dur :

| Rôle | Ce qu'il fait | Subagent(s) liés par défaut |
|---|---|---|
| `researcher` | Explore code/doc/web en lecture seule avant toute décision | `agent-explore-code`, `agent-explore-docs`, `agent-explore-web` |
| `backend-coder` | Implémente/modifie le code Java/Spring | `agent-code-java` |
| `frontend-coder` | Implémente/modifie le code Angular | `agent-code-angular` |
| `reviewer` | Relit un diff en contexte frais (gate de fin de boucle) | `agent-review-adversarial` (routine), `agent-security-reviewer` (sur demande/sensible) |

Le mapping rôle → subagent vit dans `.ai/config/subagents.yaml` (à créer,
voir tâche P1 ci-dessous), donc **changer le subagent qui tient un rôle ne
touche aucun skill ni aucun script de workflow** — seulement cette table.

### Sélection du workflow : s'appuyer sur les mécanismes natifs, pas un interpréteur custom

Plutôt que d'écrire un moteur qui « exécute » un YAML de workflow (risque de
réinventer ce que Claude Code fait déjà), le paramétrage repose sur le fait
que chacun des quatre patterns du catalogue est **invocable par son propre nom
natif** :

| Archetype | Mécanisme natif à invoquer | Comment on le sélectionne |
|---|---|---|
| `feature` | skill `workflow-dev` | `/workflow-dev` (ou délégation auto via `description`) |
| `bug-fix` | skill `workflow-debug` | `/workflow-debug` |
| `review-refactor` (diff isolé) | subagent `agent-review-adversarial` (+ `agent-security-reviewer` si sensible) | délégation directe, ou `/code-review` (skill bundlé) |
| `planning` / audit large / migration de masse | dynamic workflow sauvegardé | `/<nom-du-workflow>` avec `args` (ex. `/feature-audit src/routes/`) |

`.ai/config/subagents.yaml` porte uniquement deux informations stables : (a)
le mapping rôle → subagent (ci-dessus), (b) une table `archetype: workflow par
défaut` reprenant la colonne ci-dessus, **surchageable à l'invocation** en
demandant explicitement un autre pattern (ex. « refais ça en DEBUG » sur une
tâche taguée `feature`). `scripts/sync-config.py` n'a donc **pas** à
interpréter une grammaire de workflow : il valide ce mapping et (futur) génère
`.claude/agents/*.md` à partir des bindings rôle → subagent — cohérent avec
son garde-fou actuel (refus d'écraser sans en-tête `GENERATED`).

Schéma proposé (extrait) :

```yaml
# .ai/config/subagents.yaml
roles:
  researcher: [agent-explore-code, agent-explore-docs, agent-explore-web]
  backend-coder: [agent-code-java]
  frontend-coder: [agent-code-angular]
  reviewer: [agent-review-adversarial]   # agent-security-reviewer = override explicite

default_workflow_by_archetype:
  feature: workflow-dev
  bug-fix: workflow-debug
  review-refactor: agent-review-adversarial
  planning: { dynamic_workflow: true }   # pas de nom fixe — écrit à la demande
```

## Subagents

| Subagent | Modèle | Outils | Skills préchargés (`skills:`) | Règle de convention | `memory` | Rôle | Description (déclenchement) |
|---|---|---|---|---|---|---|---|
| `agent-explore-code` | haiku | Read, Grep, Glob | — | — | aucune | `researcher` | « Use proactively to locate code, symbols, or call sites before any change. » |
| `agent-explore-docs` | haiku | Read, Bash (ctx7), `find-docs` | `find-docs` | — | aucune | `researcher` | « Use to fetch current library/framework docs via Context7 before relying on training data. » |
| `agent-explore-web` | haiku | WebSearch, WebFetch | — | — | aucune | `researcher` | « Use for external research not covered by the codebase or Context7. » |
| `agent-code-java` | sonnet | Read, Edit, Write, Bash, Grep, Glob | `java-code-review`, `jpa-patterns`, `spring-boot-patterns`, `test-quality` | `.ai/rules/java-coding-rules.md` | aucune | `backend-coder` | « Use proactively to implement or modify Java/Spring backend code. » |
| `agent-code-angular` | sonnet | Read, Edit, Write, Bash, Grep, Glob | `angular-developer` | `.ai/rules/angular-coding-rules.md` | aucune | `frontend-coder` | « Use proactively to implement or modify Angular frontend code. » |
| `agent-security-reviewer` | opus | Read, Grep, Glob, Bash | `security-audit`, `concurrency-review` | les deux règles (lecture seule) | `project` | `reviewer` (sensible) | « Use for deliberate security/concurrency audits, not as a routine gate — escalation manuelle. » |
| `agent-review-adversarial` — **proposé** | sonnet | Read, Grep, Glob | `clean-code`, `solid-principles`, `test-quality` | les deux règles (lecture seule) | `project` | `reviewer` (routine) | « Use as the default fresh-context gate at the end of every EPCT/DEBUG loop — sees only the diff + acceptance criteria. » |

Tous les `agent-code-*`/`agent-explore-*` tournent **sans** `memory` : ce sont
des exécutions ponctuelles par feature, l'état pertinent doit vivre dans le
code/les tests, pas dans une mémoire de subagent (risque d'hypothèses
périmées). Justification du choix inverse pour les deux reviewers ci-dessous.

## Stratégie mémoire

- **Mémoire d'instructions** (déjà en place) : hiérarchie `AGENTS.md` →
  `CLAUDE.md` (+ règles `.ai/rules/*.md` scoping `paths:`), relue à chaque
  tour de la session principale **et** chargée au démarrage de chaque
  subagent. C'est la mémoire « de convention », commune à tous les rôles.
- **Mémoire persistante par subagent** (`memory: project|user|local` →
  `.claude/agent-memory/<name>/MEMORY.md`, 200 premières lignes injectées) :
  à réserver aux rôles qui **accumulent un jugement dans le temps**, pas à
  ceux qui exécutent une tâche bornée.
  - `agent-security-reviewer` et `agent-review-adversarial` (`memory:
    project`, versionné git) : bénéfice réel — mémoriser les faux positifs
    déjà tranchés par l'équipe (« ce pattern XSS-like est accepté car
    assaini en amont ») évite de re-signaler le même écart à chaque revue.
  - `agent-explore-*`, `agent-code-java`, `agent-code-angular` : **pas de
    memory**. Chaque feature est une exécution indépendante ; l'état qui
    compte (ce qui a été codé, pourquoi) doit vivre dans le code et les
    commits, pas dans un fichier de mémoire qui peut devenir périmé et
    biaiser une implémentation future.

## Liste de tâches phasée

Reprend et complète `roadmap.md` Phase 3/4 sans dupliquer — chaque tâche porte
un critère d'acceptation observable. « (roadmap) » = déjà tracée ailleurs,
séquencée ici ; « (nouveau)» = surfacée par cette analyse.

| # | Tâche | depends_on | Critère d'acceptation observable |
|---|---|---|---|
| P1 | Créer `.ai/config/subagents.yaml` (rôles + mapping archetype→workflow) — (nouveau, structure) | — | Le fichier valide sous `scripts/sync-config.py` (clé `roles:` + `default_workflow_by_archetype:` présentes) |
| P2 | Étendre `scripts/sync-config.py` : valider `subagents.yaml`, générer `.claude/agents/*.md` depuis les bindings rôle→subagent — (roadmap, architecture-biagent §11) | P1 | `scripts/sync-config.ps1` génère les 6 fichiers `.claude/agents/*.md` avec l'en-tête `GENERATED`, refuse d'écraser un fichier édité à la main |
| P3 | Créer `agent-explore-code` / `-docs` / `-web` via le skill `subagent-creator` — (roadmap Phase 3) | P2 | `claude --agents` liste les 3 agents ; déléguer une recherche de code y route sans mention explicite |
| P4 | Créer `agent-code-java` et `agent-code-angular` avec leurs `skills:`/règles — (roadmap Phase 4) | P2 | Sur une feature de test, l'agent backend ne modifie aucun fichier `.ts`/`.html` et vice-versa |
| P5 | Créer `agent-security-reviewer` (opus, `memory: project`) — (roadmap Phase 4) | P2 | Un audit volontaire détecte une faille connue injectée pour le test ; un `MEMORY.md` apparaît sous `.claude/agent-memory/agent-security-reviewer/` après un run |
| P6 | Créer `agent-review-adversarial` (sonnet, `memory: project`) — (nouveau, gate manquant) | P2 | Sur un diff contenant un écart connu vs critères d'acceptation, l'agent le signale sans accès au reste du contexte de session |
| P7 | Créer le skill `workflow-dev` (EPCT, pattern fichiers-étapes) référençant les rôles `researcher`/`backend-coder`/`frontend-coder`/`reviewer` — (roadmap Phase 3) | P3, P4, P6 | `/workflow-dev` exécute Explore→Plan→Code→Commit en déléguant chaque étape au rôle correspondant |
| P8 | Créer le skill `workflow-debug` (pattern fichiers-étapes) — (roadmap Phase 3) | P3, P4, P6 | `/workflow-debug` s'arrête aux étapes 1/3/5 pour validation utilisateur, comme documenté dans `workflows.md` |
| P9 | Ajouter un hook `Stop` qui bloque la fin de session si le build/tests ne sont pas verts — (roadmap backlog hooks, gate déterministe citée dans `workflows.md`) | P7, P8 | Terminer une session avec un test rouge déclenche un blocage (jusqu'à 8 essais avant passage en force) |
| P10 | Écrire et sauvegarder un premier dynamic workflow (`.claude/workflows/feature-audit.js` ou équivalent) pour l'archetype `planning`/audit large — (nouveau) | P3, P4, P6 | `/feature-audit <args>` apparaît dans `/workflows`, fan-out de workers réutilisant `agent-explore-code`/`agent-review-adversarial` |
| P11 | Documenter le déclencheur `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` (drapeau, pas d'activation par défaut) et le cas d'usage retenu (hypothèses concurrentes en debug) — (roadmap Phase 4 « Agent Teams (expérimental) ») | P3, P4 | Une ligne dans `AGENTS.md`/`CLAUDE.md` explique comment et quand l'activer, sans l'activer par défaut |

## Questions ouvertes

- **Version Claude Code installée par l'équipe** : les dynamic workflows
  requièrent v2.1.154+ et un toggle `/config` (Pro et plus). À vérifier avant
  de committer P10 — sinon, le pattern « audit large » retombe sur un simple
  enchaînement manuel de subagents (moins puissant mais fonctionnel dès
  aujourd'hui).
- **Faut-il un `agent-review-adversarial` séparé de `agent-security-reviewer`
  dès le départ (P6), ou commencer par une seule revue (opus) et scinder
  seulement si le coût/latence le justifie ?** Le tableau ci-dessus part du
  principe que la revue de routine (chaque diff) doit rester bon marché
  (sonnet, sans audit sécurité profond), et que l'audit opus reste une
  escalade volontaire — à confirmer avec l'équipe selon son budget.
- **Agent Teams** : aucune tâche ne l'active par défaut (coût tokens,
  expérimental, limitations de reprise de session documentées). À planifier
  uniquement si un besoin concret apparaît (debug à hypothèses concurrentes,
  revue de PR multi-angles) — ne pas l'anticiper plus que ça.
- **Faut-il committer `.claude/workflows/*.js` en clair dans le repo ?** Le
  script JS d'un dynamic workflow sauvegardé est lisible/diffable — cohérent
  avec la politique « versionner ce qui est projet » du kit (§7
  `architecture-biagent.md`), mais à valider une fois P10 produit un premier
  exemple concret.

## Sources

- Subagents — <https://code.claude.com/docs/en/sub-agents> (vérifié 2026-06-22, repris)
- Skills — <https://code.claude.com/docs/en/skills> (vérifié 2026-06-22, repris)
- Best practices (Explore/Plan/Code) — <https://code.claude.com/docs/en/best-practices> (vérifié 2026-06-22, repris)
- Dynamic workflows — <https://code.claude.com/docs/en/workflows> (vérifié 2026-06-23, nouvelle lecture)
- Agent teams — <https://code.claude.com/docs/en/agent-teams> (vérifié 2026-06-23, nouvelle lecture)
- Fiches internes déjà vérifiées : `docs/reference/subagents.md`, `docs/reference/skills.md`, `docs/reference/workflows.md`, `docs/reference/hooks.md`
- État d'avancement et backlog : `docs/guide/roadmap.md`, `docs/guide/architecture-biagent.md` §2, §4, §11
