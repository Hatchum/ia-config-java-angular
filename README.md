# Kit de configuration IA — Claude Code + Codex — Java + Angular (monorepo Maven, Windows)

Kit de configuration **portable** et **bi-agent**, à installer dans les projets
**Java + Angular** existants de l'entreprise (monorepo Maven multi-modules : POM
parent + modules Java + un module Angular). Cible : **Windows**.

Une **seule source de vérité** alimente deux agents IA — **Claude Code**
(Anthropic) et **Codex** (OpenAI) — sans dupliquer la connaissance : on partage
**l'intention** (instructions, skills, règles métier), on **génère** le résiduel
spécifique à chaque outil (settings, permissions, hooks, subagents).

> Ce dépôt est le **kit lui-même** (un template), pas un projet applicatif.
> Ce `README.md` est sa page d'accueil ; il n'est **pas** copié dans les projets
> cibles. La procédure d'installation est dans **[`docs/INSTALL.md`](docs/INSTALL.md)**.
> L'architecture retenue et son état d'avancement sont dans
> **[`docs/TODO.md`](docs/TODO.md)** ; la roadmap d'optimisation dans
> **[`docs/IDEA.md`](docs/IDEA.md)**.

## Principe : partager l'intention, générer le résiduel

Aucun fichier technique n'est physiquement partageable entre les deux outils
(JSON pour Claude, TOML/Starlark pour Codex). On sépare donc deux natures de
configuration :

1. **Contenu intelligent** (~80 %) — instructions, skills, règles métier. Se
   mutualise **totalement** via l'import natif `@AGENTS.md` et le standard ouvert
   `SKILL.md` (suivi des liens symboliques / junctions par les deux outils).
2. **Réglages techniques** — settings, permissions, politique d'exécution, hooks,
   subagents. Ne partagent pas un fichier, mais dérivent d'une **source abstraite
   unique** (YAML dans `.ai/config/`) qui **génère** les deux projections.

⚠️ **« Rules » est un faux ami** : `.ai/rules/*.md` (et `.claude/rules`) = des
**instructions de comportement** (markdown) ; `.codex/rules/*.rules` (Starlark) =
une **politique d'exécution** (l'équivalent des permissions Claude). Voir
`docs/TODO.md` §3.

## Structure du kit
| Élément | Rôle |
|---------|------|
| `AGENTS.md` | **Source unique** des instructions (lue nativement par Codex) |
| `CLAUDE.md` | Importe `@AGENTS.md` + notes propres à Claude |
| `.ai/skills/` | **Copie unique** des skills (Java + Angular + outillage) |
| `.ai/rules/` | Règles métier markdown (comportement, path-scopées) |
| `.ai/config/` | Source abstraite YAML : `permissions.yaml`, `hooks.yaml` |
| `.claude/skills` · `.claude/rules` | Liens (junctions Windows) vers `.ai/` |
| `.claude/settings.json` | **Généré** : permissions (deny/ask/allow) + hooks |
| `.claude/hooks/` | Scripts hooks lint/format/changelog portables (`.sh` + `.ps1`) |
| `.claude/agents/` | Subagents Claude (**générés** — à venir) |
| `.agents/skills` | Lien (junction) vers `.ai/skills` — côté Codex |
| `.codex/config.toml` | **Généré** : pointeur politique d'exécution + modèle/sandbox |
| `.codex/rules/execution-policy.rules` | **Généré** : Starlark dérivé des permissions `Bash(...)` |
| `.codex/hooks.json` | **Généré** : câblage hooks Codex (`apply_patch`, `Bash`) |
| `scripts/` | Wrappers build/test + **générateur** `sync-config` (Windows `.cmd`/`.ps1`) |
| `frontend/` | Module Angular placeholder (`CLAUDE.md` per-module) |
| `docs/` | Guides humains : installation, config, architecture bi-agent, roadmap |

## Layout (vue d'ensemble)

```
mon-projet/
├── AGENTS.md                 # ① SOURCE des instructions (Codex la lit nativement)
├── CLAUDE.md                 #    "@AGENTS.md" + notes propres à Claude
│
├── .ai/                      # ② Dossier canonique partagé (la SEULE vraie copie)
│   ├── skills/               #    SKILL.md — connaissances & workflows réutilisables
│   ├── rules/                #    règles métier markdown (comportement)
│   └── config/               #    source abstraite YAML (résiduel non partageable)
│       ├── permissions.yaml  #      liste canonique unique (format Claude)
│       └── hooks.yaml        #      câblage hooks (sections claude: + codex:)
│
├── .claude/                  # ③ Côté Claude Code
│   ├── skills -> ../.ai/skills      (junction)
│   ├── rules  -> ../.ai/rules       (junction)
│   ├── agents/                      (GÉNÉRÉ — subagents, à venir)
│   ├── hooks/                       (scripts .sh + .ps1 partagés)
│   └── settings.json                (GÉNÉRÉ — permissions + hooks)
│
├── .agents/                  # ④ Côté Codex — skills (standard ouvert)
│   └── skills -> ../.ai/skills      (junction)
│
├── .codex/                   # ⑤ Côté Codex — config & sécurité (GÉNÉRÉS)
│   ├── config.toml                  (pointeur politique d'exécution)
│   ├── hooks.json                   (câblage hooks Codex)
│   └── rules/execution-policy.rules (Starlark — politique d'exécution)
│
└── scripts/sync-config.*     # ⑥ Générateur : YAML → settings/rules/toml/hooks
```

Tout fichier **généré** porte un en-tête de garde
`GENERATED FROM .ai/config — DO NOT EDIT DIRECTLY` et le générateur **refuse
d'écraser** un fichier sans ce marqueur.

## Skills inclus
Chargés à la demande ; chaque skill se décrit via son `SKILL.md`. Source unique
dans `.ai/skills/`, vue par les deux agents (junctions `.claude/skills` et
`.agents/skills`).
- **Java** : revue de code, tests (JUnit 5 + AssertJ), JPA, Spring Boot, sécurité
  (OWASP), concurrence, design patterns, SOLID, clean code, audit Maven, migration
  Java, logging, revue d'API REST, revue d'archi, changelog, git-commit, tri
  d'issues, smells de perf.
- **Angular** : `angular-developer`, `angular-new-app`.
- **Outils externes (CLI, remplacent les MCP)** : `find-docs` (doc à jour via
  Context7), `playwright` (visuel / E2E), `api-testing` (HTTPie + jq).
- **Méta / outillage** : `prompt-creator`, `skill-creator`, `subagent-creator`,
  `find-skills`, `firecrawl-deep-research`.

L'équipe ajoute ses propres skills dans `.ai/skills/` (vus par les deux agents).

> **MCP retiré.** Plus de serveur MCP à maintenir : chaque outil externe est
> encapsulé dans un **skill** qui invoque sa **CLI** (`gh`, `mvn`, `npm`…).
> `docs/MCP.md` reste à titre historique. **Accès direct BDD interdit** par
> politique (clients `psql`/`mysql`/… en `deny` dans `permissions.yaml`).

## Installation
Voir **[`docs/INSTALL.md`](docs/INSTALL.md)** : copier le kit dans le monorepo
cible, poser les junctions (`mklink /J`), remplir les `<PLACEHOLDER>` en lisant le
vrai code (POM parent, modules, `package.json`), puis lancer le générateur :

```powershell
scripts\sync-config.ps1   # YAML .ai/config → settings.json + .codex/*
```

## Principes
- **Une source, deux projections** — l'intention se mutualise, le technique se
  génère ; les fichiers par-outil sont de simples **routeurs**.
- **Self-contained / portable** — aucune dépendance à une config perso/globale ;
  scripts portables (résolution racine via `git rev-parse` à défaut de
  `CLAUDE_PROJECT_DIR`).
- **Baseline + placeholders** — pas d'architecture ni de modules inventés ; tout
  est paramétré par `<PLACEHOLDER>`.
- **Windows d'abord** — préférer l'import `@AGENTS.md` (pas de droits) et les
  junctions aux symlinks (droits admin requis).
- **Secrets hors dépôt** — tokens / clés API en variables d'environnement,
  jamais commités.

## Conventions
- **Commits :** [Conventional Commits](https://www.conventionalcommits.org/)
  (voir `AGENTS.md` → Commit convention, via le skill `git-commit`).
- **Décidé par l'équipe (non imposé) :** le modèle de branches / workflow git.

## Documentation
- Architecture bi-agent + état d'avancement → [`docs/TODO.md`](docs/TODO.md)
- Roadmap d'optimisation → [`docs/IDEA.md`](docs/IDEA.md)
- Installation → [`docs/INSTALL.md`](docs/INSTALL.md)
- Config (permissions, hooks, subagents) → [`docs/CONFIG.md`](docs/CONFIG.md)
- MCP (historique — remplacé par skills+CLI) → [`docs/MCP.md`](docs/MCP.md)
- Build & test → wrappers `scripts/` (résumé dans `AGENTS.md`)
- Création de subagents → skill `subagent-creator` ; provenance dans
  [`docs/subagent-creator-research.md`](docs/subagent-creator-research.md) et
  [`docs/subagent-creator-prompt.md`](docs/subagent-creator-prompt.md). Artefacts
  **internes au kit** — non copiés dans la cible.
