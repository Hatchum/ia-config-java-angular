# Structure agentique pour le développement de features Java/Angular — v2 (subagents en session, SOP paramétrables)

> Source vérifiée : [Run agents in parallel](https://code.claude.com/docs/en/agents) ·
> [Orchestrate dynamic workflows](https://code.claude.com/docs/en/workflows) ·
> [Create custom subagents](https://code.claude.com/docs/en/sub-agents) ·
> [Configure permissions](https://code.claude.com/docs/en/permissions) ·
> Vérifié le 2026-06-24 (les quatre pages ci-dessus ont été re-fetchées ce
> jour-là pour confirmer la limite des dynamic workflows, les plafonds de
> concurrence, la liste d'outils indisponibles aux subagents, et les modes de
> permission — voir §Sources pour le détail des citations).
> Fiches internes déjà vérifiées et reprises sans nouvelle lecture :
> `docs/reference/subagents.md`, `docs/reference/skills.md`,
> `docs/reference/workflows.md` (vérifiées 2026-06-22).
> Généré à partir de `docs/research/prompt-structure-agentique.md` (skill
> `prompt-creator`).

## ⚠️ Ce document remplace une version précédente — discrepancy à signaler

Le prompt source (`prompt-structure-agentique.md`, §Contexte) affirme que
« `docs/research/agentique.md` exists but is **empty** ». **Ce n'est pas ce
qui a été observé en exécutant ce prompt** (étape 1 : « Confirm directly —
don't assume »). Le fichier contenait déjà une v1 complète, générée par une
itération antérieure du même prompt **avant sa respécialisation** : cette v1
retenait les **dynamic workflows natifs** comme mécanisme porteur pour
l'archetype `planning`/audit large, et structurait `subagents.yaml` autour
d'un mapping `archetype: workflow-natif-par-nom` plutôt que d'un véritable
axe SOP paramétrable.

La respécialisation (voir l'en-tête de `prompt-structure-agentique.md`)
restreint explicitement le mécanisme d'exécution aux **subagents en session
uniquement**, pour la raison donnée plus bas (§Contexte) — incompatible avec
la v1, qui n'excluait pas les dynamic workflows de l'exécution courante. Ce
document **remplace donc la v1 dans son intégralité** plutôt que de la
patcher ; rien de la v1 n'est perdu silencieusement : son contenu réutilisable
(catalogue de skills déjà présents, table de rôles, stratégie mémoire) est
repris et corrigé ci-dessous.

## Contexte

Ce document répond à la demande respécialisée de
`prompt-structure-agentique.md` : concevoir et **générer réellement** une
couche d'orchestration paramétrable — subagents en session, workflows à
rôles avec marqueur parallèle/séquentiel, SOP = f(rôle, archétype) + surcouche
d'équipe, et escalade humaine réactive (HITL) — pour le kit bi-agent
(Claude Code + Codex) de ce dépôt. Il fait avancer le backlog **Phase 3/4**
de [`roadmap.md`](../guide/roadmap.md) et le chantier **« Subagents »** marqué
❌ dans [`architecture-biagent.md` §11](../guide/architecture-biagent.md).

**Constat directeur (vérifié 2026-06-24, citation exacte) :** la page
officielle *Orchestrate dynamic workflows* indique, dans son tableau
« Behavior and limits » :

> *"No mid-run user input — Only agent permission prompts can pause a run.
> For sign-off between stages, run each stage as its own workflow."*

Ceci entre en conflit direct avec l'exigence de ce kit : l'orchestrateur doit
pouvoir interroger l'humain **au moment où** un subagent signale un problème
— pas seulement à une frontière d'étape planifiée à l'avance. Les *Agent
Teams* (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, confirmé « Experimental and
disabled by default ») n'offrent pas davantage de canal d'escalade vers
l'humain — seulement une messagerie pair-à-pair entre coéquipiers.
**Décision : ce design utilise les subagents en session comme seul
mécanisme d'exécution.** Plusieurs appels `Agent`/`Task` indépendants dans un
même message = le cas parallèle ; des appels sur des tours successifs,
chacun dépendant du résultat précédent = le cas séquentiel ; imbrication
jusqu'à la profondeur 5 (confirmé `docs/reference/subagents.md` + re-fetch
2026-06-24). Les dynamic workflows et Agent Teams restent une **proposition
d'extension future** pour du travail en masse à faible granularité HITL
(ex. audit dépôt entier) — jamais la boucle par défaut (voir tâche P10).

## Inventaire (existant vs nouveau, observé directement à l'exécution)

| Brique | État observé | Référence |
|---|---|---|
| `.ai/config/permissions.yaml`, `.ai/config/hooks.yaml` + générateur | ✅ en place | `scripts/sync-config.py` |
| `.ai/config/workflows.yaml` | ❌ n'existait pas → ✅ **créé par ce run** | voir §Artefacts |
| `.ai/config/subagents.yaml` | ❌ n'existait pas → ✅ **créé par ce run** | voir §Artefacts |
| `.ai/config/sop-overrides.yaml` (surcouche équipe) | ❌ n'existait pas → ✅ **créé par ce run** | voir §Artefacts |
| `.claude/agents/` | ❌ vide → ✅ **7 fichiers créés par ce run** | voir §Artefacts |
| `docs/research/agentique.md` | ⚠️ contenait déjà une v1 (voir avertissement ci-dessus) → ✅ **remplacé par ce run** | ce fichier |
| ~30 skills (Java, Angular, méta-outillage) | ✅ en place, réutilisés tels quels | `.ai/skills/*/SKILL.md` |
| Règles Java/Angular | ✅ en place, réutilisées tels quelles | `.ai/rules/*.md` |
| Anatomies d'archétype (planning/feature/bug-fix/review-refactor) | ✅ en place, réutilisées comme base SOP | `.ai/skills/prompt-creator/references/dev-orchestration.md` |
| Skills `feature` / `bugfix` (packaging fichiers-étapes) | ❌ n'existaient pas → ✅ **créés dans une passe suivante du même run** (voir §Artefacts) | `.ai/skills/feature/`, `.ai/skills/bugfix/` |
| `scripts/sync-config.py` étendu pour `workflows.yaml`/`subagents.yaml` | ❌ pas fait (volontairement — voir §Génération) | voir tâche P1 |

## Workflows catalogue

Trois patterns, tous exécutés par dispatch direct de subagents en session
(jamais par un script de dynamic workflow) — données réelles dans
`.ai/config/workflows.yaml`.

| Workflow (clé YAML) | Archétype déclencheur | Étapes ordonnées (`id: role`) | Parallèle vs séquentiel | Gate(s) de vérification |
|---|---|---|---|---|
| `workflow-dev` | `feature` | `explore: researcher` → `implement-backend: backend-coder` ∥ `implement-frontend: frontend-coder` → `review: reviewer` | `explore` = `dispatch: parallel` (plusieurs `agent-explore-*` en un message) ; `implement-backend`/`implement-frontend` = `dispatch: parallel` entre eux si fichiers disjoints, chacun séquentiel après `explore` ; `review` = séquentiel, dépend des deux | `implement-backend` : `scripts\test.cmd`/`mvn -q test` + `scripts\build.cmd` verts ; `implement-frontend` : `ng test` + `ng build` verts, lint clean ; `review` : aucun finding sévérité haute |
| `workflow-debug` | `bug-fix` | `analyze: researcher` → `fix: backend-coder\|frontend-coder` → `review: reviewer` | tout séquentiel (la reproduction doit précéder le fix, qui doit précéder la revue) | `fix` : test de non-régression rouge avant / vert après, suite complète verte ; `review` : aucun finding sévérité haute |
| `workflow-review` | `review-refactor` | `review: reviewer` (seule étape) | séquentiel, invocable seul sur un diff/PR existant, ou en fin de `workflow-dev`/`workflow-debug` | tableau de findings produit ; si correctifs appliqués, tests re-passés verts |

**Décision nommée, explicitement signalée comme un ajout** (pas une
correction silencieuse) : les **dynamic workflows et Agent Teams sont exclus
du mécanisme d'exécution** ci-dessus, pour la raison citée en §Contexte. La
note « Dynamic workflows / revue adverse » de `docs/reference/workflows.md`
(lignes 84-91, vérifiée 2026-06-22) reste correcte sur l'existence du
mécanisme mais ne mentionnait pas cette limite de mi-run — c'est une **lecture
neuve** apportée par cette analyse (vérifiée 2026-06-24), pas une remise en
cause de ce que `workflows.md` affirmait déjà. Conservés comme **proposition
d'extension future**, sans nom de workflow fixe (`default_archetype_workflow.planning:
null` dans `workflows.yaml`) — voir tâche P10.

Choix de nommage : les workflows YAML (`workflow-dev`, `workflow-debug`) et
leurs skills correspondants (`feature`, `bugfix`) portent des noms distincts
— les workflows sont des clés d'orchestration abstraites (pour `subagents.yaml`
et `default_archetype_workflow`), les skills sont des points d'entrée
conviviales (invocation de l'utilisateur : `feature "<description>"`, non
`workflow-dev "<description>"`). Les skills eux-mêmes lisent et executent le
workflow YAML mappé à leur archétype (`feature` → `workflow-dev`, `bugfix` →
`workflow-debug`). `workflow-review` est, lui, **vraiment nouveau** : ni
`roadmap.md` ni `skills.md` n'anticipaient un pattern de revue autonome —
ajouté ici pour couvrir le cycle complet de livraison d'une feature, comme
demandé à l'étape 3 du prompt source.

## Rôles & paramétrage SOP

### (a) La couche de rôles — données réelles dans `subagents.yaml` → `roles:`

```yaml
roles:
  researcher: [agent-explore-code, agent-explore-docs, agent-explore-web]
  backend-coder: [agent-code-java]
  frontend-coder: [agent-code-angular]
  reviewer: [agent-review-adversarial, agent-security-reviewer]
```

Chaque étape de `workflows.yaml` référence un `role:`, jamais un nom de
subagent en dur — changer le subagent qui tient un rôle ne touche que cette
table.

### (b) `sop(role, archetype)` — données réelles dans `subagents.yaml` → `sop:`

```yaml
sop:
  backend-coder:
    feature:
      anatomy_source: .ai/skills/prompt-creator/references/dev-orchestration.md#feature
      flavor: "TDD-flavored — write/adjust the failing test before the implementation that makes it pass"
    bug-fix:
      anatomy_source: .ai/skills/prompt-creator/references/dev-orchestration.md#bug-fix
      flavor: "reproduce -> root-cause -> smallest fix -> regression test, in that order"
  # researcher / frontend-coder / reviewer suivent le même schéma — voir le fichier complet
```

Le `anatomy_source` pointe vers l'anatomie d'archétype déjà définie dans
`dev-orchestration.md` (planning/feature/bug-fix/review-refactor) ; `flavor`
est la seule prose ajoutée par rôle — un déport, pas une duplication. Chaque
subagent (voir leur system prompt en §Subagents) est instruit de lire cette
clé pour son propre rôle × l'archétype reçu dans le prompt de délégation,
**avant** de commencer le travail.

### (c) Surcouche d'équipe — `subagents.yaml` → `team_overrides:` + `.ai/config/sop-overrides.yaml`

```yaml
# subagents.yaml
team_overrides: .ai/config/sop-overrides.yaml
```

```yaml
# sop-overrides.yaml (vide par défaut — gabarit)
overrides:
  <role>:
    <archetype>:
      add_steps: [{ after: "<ancre>", step: "<étape ajoutée>" }]
      remove_steps: ["<ancre à retirer>"]
      replace_steps: { "<ancre>": "<étape de remplacement>" }
```

Une équipe peut patcher une procédure **sans toucher** `subagents.yaml`,
`workflows.yaml`, ni aucun `.claude/agents/*.md` — chaque subagent lit ce
fichier pour sa propre clé rôle × archétype avant de démarrer (instruction
intégrée dans son system prompt, §Subagents). Deux axes indépendants et
cumulables, comme demandé : le SOP varie déjà par (rôle, archétype) avant
toute surcharge d'équipe.

### Sélection du workflow — `workflows.yaml` → `default_archetype_workflow:`

```yaml
default_archetype_workflow:
  feature: workflow-dev
  bug-fix: workflow-debug
  review-refactor: workflow-review
  planning: null   # proposition future, hors mécanisme d'exécution retenu — voir P10
```

Surchargeable **par invocation** : un humain peut demander explicitement
« refais ça en workflow-debug » sur une tâche taguée `feature` sans éditer ce
fichier — l'orchestrateur honore la demande directement.

## Mécanisme d'escalade HITL

### La convention de token de statut — donnée réelle, `subagents.yaml` → `hitl:`

Chaque subagent termine son tour par exactement une ligne, la dernière de sa
sortie :

```
STATUS: completed
STATUS: blocked — <one-line reason>
STATUS: needs_clarification — <one-line question>
```

Texte brut plutôt que XML, puisque les subagents de ce kit renvoient un
résumé libre à la session parente (pas une enveloppe parseable par défaut).
Vocabulaire adapté du contrat `<handoff>` de
`.ai/skills/prompt-creator/references/dev-orchestration.md` (`status`,
`<blockers>`, `<open_questions>`), traduit en une convention de texte plat
puisque ces subagents-ci ne sont pas instruits d'émettre du XML.

### Règle de décision mécanique de l'orchestrateur

| Dernière ligne non vide du résumé du subagent | Action de l'orchestrateur |
|---|---|
| `STATUS: completed` (et la vérification rapportée, si l'étape en a une, est réellement `pass`) | Continuer à l'étape suivante du workflow |
| `STATUS: blocked — ...` | Appeler `AskUserQuestion` **avant** tout nouveau dispatch de cette branche du workflow, avec la raison verbatim |
| `STATUS: needs_clarification — ...` | Appeler `AskUserQuestion` **avant** tout nouveau dispatch, avec la question verbatim |
| Ligne absente, mal formée, ou contredite par le propre résultat de vérification rapporté par l'agent (ex. `completed` mais vérification = `fail`) | Filet de sécurité : traiter comme `needs_clarification`, appeler `AskUserQuestion` |

Cette règle est délibérément mécanique (regex sur la dernière ligne, pas
d'interprétation) pour que l'orchestrateur puisse trancher sans ambiguïté
entre « continuer » et « escalader ». `AskUserQuestion` est confirmé
**indisponible aux subagents eux-mêmes** (`docs/reference/subagents.md` +
re-fetch 2026-06-24 de la liste exacte : *"AskUserQuestion, EnterPlanMode,
ExitPlanMode (unless permissionMode: plan), ScheduleWakeup,
WaitForMcpServers"*) — l'escalade vers l'humain est donc nécessairement
portée par l'orchestrateur (la session principale), jamais par le subagent
qui a détecté le blocage.

## Subagents

7 fichiers `.claude/agents/*.md`, tous créés par ce run (`.claude/agents/`
était vide à l'observation directe, étape 1).

| Subagent | Modèle | Outils | Skills préchargés | Règle de convention | `memory` | Rôle | Description (déclenchement) |
|---|---|---|---|---|---|---|---|
| `agent-explore-code` | haiku | Read, Grep, Glob | — | — (auto-chargées) | aucune | `researcher` | « Use proactively to locate code, symbols, call sites, or existing patterns … before any change. » |
| `agent-explore-docs` | haiku | Read, Bash, Grep, Glob | `find-docs` | — | aucune | `researcher` | « Use to fetch current library/framework/API documentation via the ctx7 CLI … » |
| `agent-explore-web` | haiku | WebSearch, WebFetch | — | — | aucune | `researcher` | « Use for external research not covered by the codebase or by Context7 library docs … » |
| `agent-code-java` | sonnet | Read, Edit, Write, Bash, Grep, Glob | `java-code-review`, `jpa-patterns`, `spring-boot-patterns`, `test-quality` | `.ai/rules/java-coding-rules.md` | aucune | `backend-coder` | « Use proactively to implement or modify Java/Spring Boot backend code … » |
| `agent-code-angular` | sonnet | Read, Edit, Write, Bash, Grep, Glob | `angular-developer` | `.ai/rules/angular-coding-rules.md` | aucune | `frontend-coder` | « Use proactively to implement or modify Angular frontend code … » |
| `agent-review-adversarial` | sonnet | Read, Grep, Glob | `clean-code`, `solid-principles`, `test-quality` | les deux règles (lecture seule) | `project` | `reviewer` (routine) | « Use proactively as the default fresh-context gate at the end of every feature/bug-fix workflow … » |
| `agent-security-reviewer` | opus | Read, Grep, Glob, Bash | `security-audit`, `concurrency-review` | les deux règles (lecture seule) | `project` | `reviewer` (escalade sensible) | « Use for deliberate security/concurrency audits on request, or when agent-review-adversarial flags a security-sensitive surface … » |

Chaque fichier embarque, dans cet ordre : un commentaire HTML « ROLE
BINDING » (la donnée projetable depuis `subagents.yaml`, hand-synced pour
l'instant), le rôle en prose, les règles/skills gouvernants, une section
« Load your SOP before starting » qui pointe vers `subagents.yaml` →
`sop.<role>.<archetype>` puis `sop-overrides.yaml`, et la convention de token
de statut en fin de section.

## Stratégie mémoire — corrigé le 2026-06-24 (v2, modèle à 3 niveaux)

> **Correction de fraîcheur (interne à ce document)** : la version
> précédente de cette section ne couvrait que 2 des 3 niveaux de mémoire
> réellement documentés par Claude Code — le niveau « auto memory » de la
> session principale (ci-dessous) avait été omis. Corrigé après vérification
> directe de <https://code.claude.com/docs/en/memory> (fetché 2026-06-24).
> Aucun changement de comportement n'en découle (ce niveau est natif, actif
> par défaut, rien à configurer) — seulement une lacune de documentation.

Claude Code distingue **3 mécanismes de mémoire**, pas 2 :

| Niveau | Qui écrit | Emplacement réel | Portée | Chargé au démarrage |
|---|---|---|---|---|
| **1. `CLAUDE.md`/`AGENTS.md`** (instructions) | l'humain | `AGENTS.md`→`CLAUDE.md` (racine, importé), `.ai/rules/*.md` (`paths:`) | règles, pas des constats appris | en entier, à chaque session **et** au démarrage de chaque subagent personnalisé (confirmé : seuls les agents intégrés *Explore*/*Plan* sautent cette étape) |
| **2. Auto memory (session principale)** | Claude lui-même, automatiquement | `~/.claude/projects/<projet>/memory/MEMORY.md` (+ fichiers thématiques) — **machine-local, jamais commité**, un dossier par dépôt git (partagé entre worktrees) | apprentissages de session (commandes de build, conventions découvertes, préférences) — pas un fichier de ce dépôt | 200 premières lignes / 25 Ko de `MEMORY.md` ; activé par défaut depuis Claude Code v2.1.59 (`autoMemoryEnabled`) |
| **3. Mémoire persistante par subagent** (`memory: project\|user\|local`) | le subagent, sur instruction explicite de son system prompt | `.claude/agent-memory/<name>/MEMORY.md` (scope `project`, **versionné git**) ou équivalents `user`/`local` | jugement accumulé propre à un rôle nommé | 200 premières lignes / 25 Ko du `MEMORY.md` de cet agent |

Le niveau 2 (auto memory) est **natif et déjà actif** dans toute session de ce
kit sans configuration de notre part — il n'apparaît dans aucun fichier de
`.ai/config/` parce qu'il n'y a rien à y déclarer. Il joue, pour
l'orchestrateur (la session principale qui exécute `workflow-dev`/
`workflow-debug`), le rôle de mémoire de contexte stable que `subagents.yaml`
ne couvre pas : retenir d'une session à l'autre que `scripts\test.cmd` est la
bonne commande, que les clients DB en direct sont interdits, etc. — à
distinguer de `agent-memory/`, qui est git-partagé et scope à un **rôle**, pas
à la session.

Seul le niveau 3 concerne les rôles de ce kit, et seulement deux d'entre eux —
décision inchangée, justifiée ci-dessous :

- `agent-review-adversarial` et `agent-security-reviewer` (`memory:
  project`, versionné git) : bénéfice réel — mémoriser les faux positifs déjà
  tranchés par l'équipe évite de re-signaler le même écart accepté à chaque
  revue. **Activé concrètement par ce run** : `.claude/agent-memory/
  agent-review-adversarial/MEMORY.md` et `.claude/agent-memory/
  agent-security-reviewer/MEMORY.md` existent maintenant sur disque (avant
  cette passe, le dossier `.claude/agent-memory/` n'existait pas du tout —
  confirmé par inspection directe — donc la mémoire était *configurée* dans
  le frontmatter mais jamais *amorcée*). Les deux fichiers sont volontairement
  vides au-delà de leur en-tête : c'est le travail réel des agents, pas ce
  run, qui doit les peupler.
- `agent-explore-*`, `agent-code-java`, `agent-code-angular` : **toujours pas
  de memory**, décision maintenue. Chaque feature est une exécution
  indépendante ; l'état qui compte (ce qui a été codé, pourquoi) doit vivre
  dans le code et les commits, pas dans un fichier de mémoire qui peut
  devenir périmé et biaiser une implémentation future. Si ce choix doit être
  reconsidéré (ex. `agent-explore-code` qui apprendrait la structure du repo
  d'une session à l'autre), c'est un changement délibéré à discuter, pas une
  extension par défaut.

## Identifiants des subagents — comment l'orchestrateur suit leur travail

Confirmé 2026-06-24 (`docs/en/sub-agents` + `docs/en/hooks`, fetchés) : chaque
subagent a **deux identifiants de nature différente**, tous deux déjà actifs
nativement — rien à activer dans ce kit pour qu'ils existent.

| Identifiant | Nature | Source | Usage par l'orchestrateur |
|---|---|---|---|
| `name` (ex. `agent-review-adversarial`) | **Statique** — un par fichier `.claude/agents/*.md`, c'est le champ frontmatter `name:` | défini une fois dans le fichier agent | Référencé dans `roles:` de `subagents.yaml` ; c'est ce que reçoivent les hooks comme `agent_type` ; c'est le nom utilisable en `@agent-<name>` ou `Agent(<name>)` |
| `agent_id` | **Dynamique** — un par *invocation* (deux dispatches du même `agent-code-java` dans le même run obtiennent deux `agent_id` différents) | assigné par Claude Code au moment du dispatch | Renvoyé à l'orchestrateur à la fin du tour de l'agent ; permet de **reprendre** un subagent précis via `SendMessage` (`to: <agent_id>`) plutôt que d'en relancer un nouveau |

Trois conséquences concrètes pour le suivi du travail :

1. **Transcript complet par invocation** : chaque exécution est persistée en
   entier (tool calls, raisonnement, résultat) dans
   `~/.claude/projects/<projet>/<sessionId>/subagents/agent-<agentId>.jsonl`
   — indépendamment de la compaction de la session principale, conservé
   `cleanupPeriodDays` jours (30 par défaut). C'est le journal le plus
   complet pour vérifier ce qu'un agent a réellement fait.
2. **Hooks `PreToolUse`/`PostToolUse`** reçoivent `agent_type` et `agent_id`
   dans leur payload JSON dès que l'appel vient d'un subagent (absent pour un
   appel de la session principale) — confirmé verbatim sur `docs/en/hooks`.
3. **Gap comblé par ce run** : `.claude/hooks/log-changes.sh`/`.ps1` (le hook
   générique de log de fichiers modifiés, voir `hooks.yaml`) **n'exploitait
   pas** ces deux champs jusqu'à cette passe. Voir la section suivante pour le
   détail complet — ce premier correctif a depuis été absorbé dans un système
   de journalisation à 2 fichiers (options A+B+D ci-dessous).

Ces mécanismes restent de l'**observabilité a posteriori** (transcript, logs)
— ils ne remplacent pas la vérification de fond : le hook `Stop` proposé
(tâche P4) reste la seule garde qui empêcherait une session de se terminer sur
un build/tests non réellement verts, plutôt que de se fier au seul `STATUS:`
auto-déclaré.

## Journalisation humainement traçable (options A + B + D)

Demande explicite : « ajouter un ou plusieurs fichiers de log qui permettent à
un humain de tracer le travail de chaque agent », avec obligation de fonder
les choix sur la documentation officielle plutôt que sur un design *ad hoc*.
Option C (auto-déclaration par le LLM lui-même dans un fichier) a été écartée
dès la proposition : la documentation des hooks justifie leur existence
précisément par leur caractère **déterministe**, par opposition à une action
que le modèle « choisit » de faire — un journal qui dépend de la bonne volonté
du LLM à s'auto-rapporter n'a pas cette garantie.

Deux fichiers JSON Lines, tous deux locaux et gitignorés
(`.claude/logs/` — voir `.gitignore`), tous deux écrits par des hooks
déterministes (jamais par le LLM) :

| Fichier | Écrit par | Événement(s) | Contenu d'une ligne |
|---|---|---|---|
| `.claude/logs/agent-runs.jsonl` | `log-agent-lifecycle.sh`/`.ps1` (**option B**) | `SubagentStart`, `SubagentStop` | `{timestamp, event: subagent_start\|subagent_stop, session_id, agent_type, agent_id}` — qui a tourné, quand, combien de temps (delta entre les deux lignes du même `agent_id`) |
| `.claude/logs/agent-activity.jsonl` | `log-changes.sh`/`.ps1` (**option A**, étend l'ancien `changes.local.log` désormais figé/legacy) + `log-worktree-snapshot.sh`/`.ps1` (**option D**) | `PostToolUse` (Write\|Edit\|MultiEdit / `apply_patch`) et `Stop`/`SubagentStop` | `{timestamp, event: tool_edit\|worktree_snapshot, session_id, agent_type, agent_id, ...}` — `tool_edit` porte `tool`+`file` (issu du payload de l'outil) ; `worktree_snapshot` porte `status`+`file` (issu d'un scan `git status --porcelain`) |

Pourquoi deux fichiers au lieu d'un seul fourre-tout : l'un répond à « qui a
tourné et quand » (B, sans notion de fichier), l'autre à « qu'est-ce qui a
changé et qui l'a fait » (A+D, sans notion de durée de vie d'un agent) — deux
questions différentes qu'un humain pose rarement en même temps.

Pourquoi A et D écrivent dans le **même** fichier plutôt que deux fichiers
séparés : ce sont deux vues complémentaires de la même question (« quels
fichiers ont changé »), distinguées par le champ `event`. A capture chaque
édition au moment précis de l'appel d'outil (`Write`/`Edit`/`MultiEdit`/
`apply_patch`) ; D comble le trou que A ne peut pas voir — une modification
de fichier faite via une commande `Bash` brute (`sed`, un script, `mv`...) ne
passe jamais par ces outils, donc jamais par le hook `PostToolUse` de A. La
doc officielle l'indique explicitement : *« If your hook must see every file
change, such as for compliance scanning or audit logging, add a Stop hook
that scans the working tree once per turn »* — c'est exactement le rôle de D,
greffé sur `Stop` (session principale) et `SubagentStop` (un subagent qui a pu
modifier des fichiers via Bash sans que A l'ait vu). D ne tente pas de
dédupliquer contre A : c'est un instantané `git status --porcelain` complet à
chaque fin de tour, pas un journal différentiel — un humain corrèle les deux
`event` par `timestamp`/`agent_id` si besoin.

Détails d'implémentation notables :
- Les deux scripts de logging partagent une fonction utilitaire commune
  `jsonl_append` (`.claude/hooks/lib/json.sh`) / `Add-JsonLine`
  (`.claude/hooks/lib/json.ps1`), sur le même modèle de repli que `json_field`
  existant : `jq` (préféré, échappement JSON correct) → interpréteur Python
  détecté (`_hook_python`, qui sait éviter le stub Microsoft Store de
  `python3` sous Windows) → sortie naïve non échappée en dernier recours.
  Validé sur ce poste, qui n'a pas `jq` installé : le repli Python produit du
  JSON valide.
- Le `matcher: ".*"` sur `SubagentStart`/`SubagentStop` matche tout type
  d'agent (regex supportée par le champ `matcher`, confirmé sur
  `docs/en/hooks`) — volontairement non restreint à une liste de noms pour
  rester valide si de nouveaux subagents sont ajoutés sans toucher
  `hooks.yaml`.
- `Stop` ne supporte pas de `matcher` (« doesn't support matchers and always
  fires on every occurrence », confirmé sur `docs/en/hooks`) : l'entrée
  correspondante dans `hooks.yaml` omet simplement la clé `matcher`, et
  `scripts/sync-config.py::_build_hooks` a été ajusté pour ne plus exiger
  cette clé inconditionnellement (elle levait une `KeyError` auparavant).
- Ces quatre nouveaux hooks (`SubagentStart`, `SubagentStop` ×2 commandes,
  `Stop`) sont **spécifiques à Claude Code** — ajoutés uniquement sous la
  section `claude:` de `hooks.yaml`, pas sous `codex:` (Codex ne documente pas
  d'équivalent à ces événements à ce jour).
- Régénération vérifiée : `python scripts/sync-config.py` régénère
  `.claude/settings.json` sans erreur, avec les 3 nouveaux blocs `hooks.*`
  visibles et la clé `matcher` correctement absente du bloc `Stop`. Les 3
  scripts `.sh` passent `bash -n` ; les 3 scripts ont été testés avec des
  payloads JSON synthétiques (succès, lignes JSON valides produites, repli
  Python confirmé en l'absence de `jq` sur ce poste).

## Génération — extension proposée de `scripts/sync-config.py`

Le générateur actuel (`scripts/sync-config.py`) charge `permissions.yaml` +
`hooks.yaml`, valide leurs clés, et projette 4 sorties avec un garde-fou
« refuse d'écraser sans le marqueur `GENERATED FROM .ai/config` » (logique
`_safe_write`/`_has_generated_marker`, vue dans le fichier). Ce run **n'a pas
réécrit ce script** (hors périmètre demandé), mais voici précisément
comment l'étendre, sans s'y engager :

1. **Charger** `workflows.yaml` et `subagents.yaml` (même fonction
   `load_yaml` existante).
2. **Valider** : chaque `role:` référencé par une étape de `workflows.yaml`
   existe dans `subagents.yaml` → `roles:` ; chaque subagent listé sous
   `roles:` a un fichier `.claude/agents/<name>.md` correspondant sur disque ;
   chaque `sop.<role>.<archetype>` référencé par l'archétype d'un workflow
   existe ; le chemin `team_overrides:` (donc `sop-overrides.yaml`) existe et
   se parse.
3. **Projeter**, pas régénérer en entier : injecter/rafraîchir uniquement le
   bloc `<!-- BEGIN ROLE BINDING --> ... <!-- END -->` déjà présent en tête
   de chaque `.claude/agents/<name>.md` (système prompt/outils/modèle restent
   manuels) — une extension du garde-fou `_safe_write` à la **granularité
   d'une région**, pas du fichier entier.
4. La projection côté Codex (TOML, mentionnée dans `architecture-biagent.md`
   §5 « Subagents ») reste hors périmètre de cette passe : le mécanisme
   d'exécution retenu ici (subagents en session) est spécifique à Claude
   Code ; Codex n'a pas d'équivalent direct documenté à ce jour.

## Artefacts produits (ce run)

| Fichier | Contenu |
|---|---|
| `.ai/config/workflows.yaml` | 3 workflows (`workflow-dev`, `workflow-debug`, `workflow-review`), étapes ordonnées avec `dispatch`/`depends_on`/`verification_gate`, `default_archetype_workflow` |
| `.ai/config/subagents.yaml` | `roles:` (4 rôles → 7 subagents), `sop:` (rôle × archétype → anatomie + flavor), `team_overrides:` (pointeur), `hitl:` (convention de token + règle de décision) |
| `.ai/config/sop-overrides.yaml` | Surcouche d'équipe — gabarit vide (`overrides: {}`), schéma `add_steps`/`remove_steps`/`replace_steps` documenté en commentaire |
| `.claude/agents/agent-explore-code.md` | Subagent researcher, lecture-seule code, haiku |
| `.claude/agents/agent-explore-docs.md` | Subagent researcher, doc via ctx7/`find-docs`, haiku |
| `.claude/agents/agent-explore-web.md` | Subagent researcher, recherche web externe, haiku |
| `.claude/agents/agent-code-java.md` | Subagent backend-coder, Java/Spring, sonnet |
| `.claude/agents/agent-code-angular.md` | Subagent frontend-coder, Angular, sonnet |
| `.claude/agents/agent-review-adversarial.md` | Subagent reviewer routinier, diff-only, sonnet, `memory: project` |
| `.claude/agents/agent-security-reviewer.md` | Subagent reviewer sensible/escalade, opus, `memory: project` |
| `.ai/skills/feature/SKILL.md` + 5 step files in `steps/` | Skill fichiers-étapes (pattern `docs/reference/workflows.md`) qui lit `workflows.yaml` → `workflow-dev` et dispatche explore (parallèle) → implement-backend/frontend (parallèle entre eux) → review, avec le contrôle `STATUS:`/`AskUserQuestion` à chaque étape ; spec checkpoint « specify » porté par l'orchestrateur, inséré entre explore et implement |
| `.ai/skills/bugfix/SKILL.md` + 5 step files in `steps/` | Skill fichiers-étapes mappant le pattern DEBUG officiel (Analyze→Log→Find→**Propose**→Fix→**Verify**, validation utilisateur aux étapes 1/3/5) sur les 3 rôles de `workflows.yaml` → `workflow-debug` ; le checkpoint « Propose » (choix humain entre 2-3 solutions) et la confirmation finale « Verify » sont portés par l'orchestrateur lui-même, pas par un subagent |
| `.claude/agent-memory/agent-review-adversarial/MEMORY.md` | Amorce la mémoire persistante (niveau 3) de cet agent — index vide, le dossier `.claude/agent-memory/` n'existait pas avant cette passe |
| `.claude/agent-memory/agent-security-reviewer/MEMORY.md` | Idem pour cet agent |
| `.claude/hooks/log-changes.sh` + `.ps1` (réécrits) | Option A — `PostToolUse` (Write\|Edit\|MultiEdit / `apply_patch`) écrit désormais du JSON Lines (`event: tool_edit`) dans `.claude/logs/agent-activity.jsonl` au lieu du TSV `changes.local.log` (désormais figé/legacy, toujours gitignoré) |
| `.claude/hooks/log-agent-lifecycle.sh` + `.ps1` (nouveaux) | Option B — hooks `SubagentStart`/`SubagentStop` écrivant `.claude/logs/agent-runs.jsonl` (`event: subagent_start\|subagent_stop`) |
| `.claude/hooks/log-worktree-snapshot.sh` + `.ps1` (nouveaux) | Option D — hooks `Stop`/`SubagentStop` qui scannent `git status --porcelain` et ajoutent `event: worktree_snapshot` dans `.claude/logs/agent-activity.jsonl`, pour couvrir les modifications faites via `Bash` brut |
| `.claude/hooks/lib/json.sh` + `.ps1` (étendus) | Ajout de `jsonl_append`/`Add-JsonLine`, helper JSON Lines partagé par les 3 scripts ci-dessus (repli jq → Python → naïf, même logique que `json_field`) |
| `.ai/config/hooks.yaml` (étendu) | Wiring des 4 nouvelles entrées `claude:` (`SubagentStart`, `SubagentStop` ×2 commandes, `Stop` sans `matcher`) |
| `scripts/sync-config.py` (corrigé) | `_build_hooks` n'exige plus `entry["matcher"]` inconditionnellement — le `Stop` (qui ne supporte pas de `matcher`) provoquait sinon une `KeyError` |
| `.gitignore` (étendu) | `.claude/logs/` ajouté aux artefacts locaux jamais committés |
| `docs/research/agentique.md` | Ce document (remplace intégralement la v1 — voir avertissement en tête) |

Tous les fichiers YAML ont été validés par un parse `yaml.safe_load` réussi ;
tous les frontmatters Markdown ont été validés par le même mécanisme
(présence de `name`/`description`) — voir la commande exécutée pendant ce run.

## Liste de tâches phasée

Reprend `roadmap.md` Phase 3/4 sans dupliquer — « (roadmap) » = déjà tracée
ailleurs, séquencée ici ; « (nouveau) » = surfacée par cette analyse.

| # | Tâche | depends_on | Critère d'acceptation observable | Statut |
|---|---|---|---|---|
| D1 | Créer `.ai/config/workflows.yaml` + `.ai/config/subagents.yaml` + `.ai/config/sop-overrides.yaml` (nouveau, structure) | — | Les 3 fichiers existent, `yaml.safe_load` réussit sur chacun | ✅ **fait ce run** |
| D2 | Créer les 7 fichiers `.claude/agents/*.md` (roadmap Phase 3/4, repris) | D1 | Chaque fichier a un frontmatter valide (`name`+`description`) et un system prompt avec rôle/SOP/STATUS | ✅ **fait ce run** |
| D3 | Écrire ce document (`docs/research/agentique.md`) | D1, D2 | Document committable, sections 1-12 présentes | ✅ **fait ce run** |
| D4 | Créer le skill `workflow-dev` (packaging fichiers-étapes EPCT) lisant `workflows.yaml` → `workflow-dev` (roadmap Phase 3) | D1, D2 | `/workflow-dev` (ou délégation auto sur « implémente une feature ») lit `step-0-init.md`…`step-4-report.md` et exécute Explore→Code(back/front)→Review en déléguant chaque étape au rôle correspondant, dans l'ordre/parallélisme défini dans le YAML | ✅ **fait** (passe suivante du même run, suite à une question utilisateur sur l'exécution concrète) |
| D5 | Créer le skill `workflow-debug` (packaging fichiers-étapes DEBUG, avec les checkpoints « Propose »/« Verify » portés par l'orchestrateur) lisant `workflows.yaml` → `workflow-debug` (roadmap Phase 3) | D1, D2 | `/workflow-debug` s'arrête à `step-2-propose.md` (choix humain) et `step-4-verify.md` (confirmation finale) comme documenté dans `workflows.md` | ✅ **fait** (idem D4) |
| P1 | Étendre `scripts/sync-config.py` : valider `workflows.yaml`/`subagents.yaml`, projeter le bloc ROLE BINDING dans `.claude/agents/*.md` (roadmap, architecture-biagent §11) | D1, D2 | `scripts/sync-config.ps1` valide les deux nouveaux YAML et ne touche que le bloc balisé dans chaque agent file, refuse toujours d'écraser un fichier sans marqueur | ✅ **fait 2026-07-01** (`validate_orchestration` + `project_role_bindings` ; testé : validation négative OK, projection idempotente) |
| P4 | Ajouter un hook `Stop` qui bloque la fin de session si le build/tests ne sont pas verts (roadmap backlog hooks, gate déterministe citée dans `workflows.md`) — distinct des hooks lint/format déjà livrés | D4, D5 | Terminer une session avec un test rouge déclenche un blocage (jusqu'à 8 essais avant passage en force) | ✅ **fait 2026-07-01** (`verify-on-stop.sh`/`.ps1`, câblé sur `Stop` via hooks.yaml ; inerte tant que `VERIFY_CMD` n'est pas remplie dans lib/checks ; anti-boucle via `stop_hook_active` plutôt qu'un compteur d'essais) |
| P5 | Tester en conditions réelles : un humain déclenche `/workflow-dev` (ou `/workflow-debug`) sur une feature/bug de test, observe au moins une escalade `STATUS: blocked`/`needs_clarification` aboutir à un `AskUserQuestion` | D4, D5 | Capture d'écran/log de session montrant l'`AskUserQuestion` déclenché par le token de statut, ou par le checkpoint « Propose » du DEBUG loop | backlog |
| P6 | Ajouter une entrée de surcharge réelle dans `sop-overrides.yaml` pour une équipe pilote, vérifier qu'aucun fichier YAML/agent n'a dû être modifié (nouveau, validation de l'axe (c)) | D1 | Le subagent concerné applique le patch et le mentionne dans son résumé | backlog |
| P7 | (proposition future) Écrire et sauvegarder un premier dynamic workflow (`.claude/workflows/<nom>.js`) pour l'archétype `planning`/audit large — hors mécanisme d'exécution par défaut de ce document | D2 | `/<nom>` apparaît dans `/workflows`, fan-out de workers réutilisant les définitions `agent-explore-*`/`agent-review-adversarial` existantes comme types de subagent | backlog (proposition explicite, pas une tâche d'exécution par défaut) |
| P8 | (proposition future) Documenter le déclencheur `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` et le cas d'usage retenu (hypothèses concurrentes en debug), sans l'activer par défaut (roadmap Phase 4 « Agent Teams ») | — | Une ligne dans `AGENTS.md`/`CLAUDE.md` explique comment et quand l'activer | backlog (proposition) |
| P9 | Étendre la génération Codex (TOML) une fois qu'un besoin concret Codex-side existe pour ces rôles (architecture-biagent §5) | P1 | `.codex/config.toml`/équivalent projette le même mapping rôle→agent | backlog (hors périmètre actuel, noté pour mémoire) |

## Addendum 2026-07-01 — Spec-driven development (checkpoints proactifs)

Évolution demandée par l'utilisateur : une collaboration **active** — l'agent
analyse le code puis pose **toutes** les questions nécessaires avant de
développer. Le mécanisme HITL de ce document était purement **réactif**
(escalade sur `STATUS: blocked`/`needs_clarification`). Ajout d'une moitié
**proactive**, sans changer le mécanisme d'exécution (subagents en session,
orchestrateur seul détenteur d'`AskUserQuestion`) :

- **Nouvelle convention `carried_by: orchestrator`** dans `workflows.yaml` :
  une étape-checkpoint exécutée par l'orchestrateur lui-même, jamais
  déléguée. Validée par `sync-config.py` (une étape sans `role:` doit porter
  `carried_by: orchestrator` ; `depends_on` vérifié).
- **`workflow-dev` passe de 4 à 5 étapes** : `explore` →
  **`specify`** (checkpoint) → `implement-backend` ∥ `implement-frontend` →
  `review`. Le checkpoint `specify` : fusionne les « Open questions » des
  researchers avec les zones d'ombre du brouillon de spec, pose tout via
  `AskUserQuestion` (par lots, options concrètes), rédige la spec depuis
  `.ai/skills/feature/spec-template.md` dans `docs/specs/<date>-<slug>.md`,
  la fait **approuver explicitement**, et rien ne s'implémente avant. Les
  critères d'acceptation de la spec sont le contrat : les coders rapportent
  les critères couverts (sinon réponse malformée), le reviewer relit le diff
  contre la section « Acceptance criteria » verbatim (y compris le scope
  creep), le rapport final coche critère par critère et passe la spec en
  `implemented`.
- **`workflow-debug` explicite ses checkpoints** : `propose` et `confirm`
  (déjà présents comme step files du skill) deviennent des étapes
  `carried_by: orchestrator` de première classe dans le YAML.
- **Skill `workflow-dev` renuméroté** (6 step files) : step-2-specify inséré,
  implement/review/report décalés en 3/4/5 ; `spec-template.md` ajouté au
  skill. SOP flavors (`subagents.yaml`) et prompts des 7 agents mis à jour
  (researchers : section « Open questions » obligatoire en archétype
  `feature` ; coders : spec = contrat, `needs_clarification` si spec
  absente/incomplète ; reviewer : référentiel = spec). Principe résumé dans
  `AGENTS.md` → Working style (bind aussi Codex).

### Clarification subsequent (same session) — Skill naming & step file organization

Après la rédaction de cet Addendum, deux raffinements ont été appliqués pour
clarifier l'architecture :

1. **Renaming des skills pour l'interface utilisateur** : `.ai/skills/workflow-dev/`
   → `.ai/skills/feature/`, `.ai/skills/workflow-debug/` → `.ai/skills/bugfix/`.
   Rationale : les workflows YAML (`workflow-dev`, `workflow-debug`) sont des
   clés d'orchestration abstraites pour `subagents.yaml` ; les skills sont des
   points d'entrée invocables par l'utilisateur final (`feature "<description>"`,
   non `workflow-dev`). L'asymétrie deliberée (workflows abstraits vs skills
   applicatifs) reflète deux rôles distincts. Skills lisent et executent le
   workflow YAML correspondant à leur archétype (`feature` → `workflow-dev`,
   `bugfix` → `workflow-debug`).

2. **Structuration des step files** : step files maintenant organisés dans un
   sous-répertoire `steps/` au sein de chaque skill (`.ai/skills/feature/steps/step-*.md`,
   `.ai/skills/bugfix/steps/step-*.md`). Cette hiérarchie clarifie la granularité
   (skills = orchestration patterns; steps = exécution séquentielle) et permet
   l'expansion future (artefacts, templates partagés au niveau skill).

Les références dans ce document et `agentique.md` ont été mises à jour pour
refléter ces changements (chèques croisées ligne 84, 452-453). Tous les chemins
internes des step files ont été mis à jour (références croisées dans les fichier step).

## Questions ouvertes

- **`workflow-dev`/`workflow-debug` comme skills (P2/P3) vs simple
  instruction à l'orchestrateur de lire `workflows.yaml` directement sans
  skill wrapper ?** Ce document suppose que les deux skills backlog liront
  ce YAML une fois écrits, mais rien n'empêche l'orchestrateur de lire
  directement `workflows.yaml` dès aujourd'hui sans attendre P2/P3 — à
  trancher selon si l'équipe veut le déclenchement `/workflow-dev` explicite
  ou la délégation automatique par description.
- **Faut-il garder `agent-review-adversarial` séparé de
  `agent-security-reviewer` (déjà tranché ici en deux subagents distincts),
  ou les coûts/latence justifient-ils de fusionner si l'usage réel montre
  que la double revue est rarement nécessaire ?** À réévaluer après quelques
  workflows réels (voir P5).
- **Dynamic workflows (P7)** : nécessitent Claude Code v2.1.154+ et un
  toggle `/config` (confirmé 2026-06-24, disponible sur tous les plans
  payants). À vérifier sur les postes de l'équipe avant de committer P7 —
  sinon, le pattern « audit large » retombe sur un enchaînement manuel de
  subagents en session (moins puissant mais fonctionnel dès aujourd'hui).
- **Faut-il committer `.claude/workflows/*.js` en clair dans le repo une
  fois P7 produit un premier exemple ?** Cohérent avec la politique
  « versionner ce qui est projet » du kit (`architecture-biagent.md` §7),
  mais à valider concrètement.

## Sources

- Run agents in parallel — <https://code.claude.com/docs/en/agents> (fetché 2026-06-24)
- Orchestrate dynamic workflows — <https://code.claude.com/docs/en/workflows> (fetché 2026-06-24 ; citation exacte de la limite « No mid-run user input » et des plafonds 16 agents concurrents / 1000 agents par run)
- Create custom subagents — <https://code.claude.com/docs/en/sub-agents> (fetché 2026-06-24 ; confirme la liste exacte des outils indisponibles aux subagents, le tableau complet des champs de frontmatter, et les identifiants `name`/`agent_id`)
- Configure permissions — <https://code.claude.com/docs/en/permissions> (fetché 2026-06-24 ; modes de permission, interaction hooks/permissions)
- How Claude remembers your project (CLAUDE.md vs auto memory) — <https://code.claude.com/docs/en/memory> (fetché 2026-06-24 ; corrige une lacune de la v2 initiale de ce document — le niveau « auto memory » de la session principale avait été omis)
- Hooks (champs `agent_type`/`agent_id` du payload `PreToolUse`/`PostToolUse` ; schémas `SubagentStart`/`SubagentStop`/`Stop` ; exemples « Audit configuration changes » et « Log every Bash command » en JSON Lines ; absence de `matcher` sur `Stop` ; recommandation explicite du hook `Stop` scannant `git status --porcelain` pour la couverture compliance/audit) — <https://code.claude.com/docs/en/hooks> (fetché 2026-06-24)
- Hooks guide (exemples concrets corroborant les mêmes patterns JSON Lines) — <https://code.claude.com/docs/en/hooks-guide> (fetché 2026-06-24, seconde confirmation)
- Fiches internes déjà vérifiées, reprises sans nouvelle lecture : `docs/reference/subagents.md`, `docs/reference/skills.md`, `docs/reference/workflows.md` (vérifiées 2026-06-22)
- Contrat `<handoff>` et anatomies d'archétype : `.ai/skills/prompt-creator/references/dev-orchestration.md`
- État d'avancement et backlog : `docs/guide/roadmap.md`, `docs/guide/architecture-biagent.md` §2, §4, §5, §11
- Générateur existant inspecté directement : `scripts/sync-config.py`
