# Kit de configuration Claude Code — Java + Angular (monorepo Maven, Windows)

Kit de configuration Claude Code **portable**, à installer dans les projets
**Java + Angular** existants de l'entreprise (monorepo Maven multi-modules : POM
parent + modules Java + un module Angular). Cible : **Windows**.

> Ce dépôt est le **kit lui-même** (un template), pas un projet applicatif.
> Ce `README.md` est sa page d'accueil ; il n'est **pas** copié dans les projets
> cibles. La procédure d'installation est dans **[`docs/INSTALL.md`](docs/INSTALL.md)**.

## Structure du kit
| Élément | Rôle |
|---------|------|
| `CLAUDE.md` | Contrat opérationnel + index, chargé à chaque session |
| `ARCHITECTURE.md` | Carte des modules, couches, flux de données (autoritatif) |
| `.claude/settings.json` | Base des permissions (deny/ask/allow) + hooks |
| `.claude/rules/` | Loi de codage path-scopée (Java, Angular) |
| `.claude/skills/` | Skills Java (à la demande) |
| `.claude/hooks/` | Hooks lint/format + changelog (bash + PowerShell) |
| `frontend/` | Module Angular placeholder (`CLAUDE.md` per-module + skills Angular) |
| `scripts/` | Wrappers build/test Windows (`.cmd` / `.ps1`) |
| `.mcp.json` | Serveur MCP GitLab (optionnel) |
| `docs/` | Guides humains : installation, config (permissions/hooks), MCP |

## Skills inclus
Chargés à la demande par Claude Code ; chaque skill se décrit via son `SKILL.md`.
- **Java** (`.claude/skills/`) : revue de code, tests (JUnit 5 + AssertJ), JPA,
  Spring Boot, sécurité (OWASP), concurrence, design patterns, SOLID, clean code,
  audit Maven, migration Java, logging, revue d'API REST, revue d'archi,
  changelog, git-commit, tri d'issues, smells de perf.
- **Angular** (`frontend/.claude/skills/`) : `angular-developer`, `angular-new-app`.

L'équipe ajoute ses propres skills au même endroit (Java à la racine, Angular
dans le module).

## Installation
Voir **[`docs/INSTALL.md`](docs/INSTALL.md)** : copier le kit dans le monorepo
cible, puis remplir les `<PLACEHOLDER>` en lisant le vrai code (POM parent,
modules, `package.json`).

## Principes
- **Self-contained / portable** — aucune dépendance à une config perso/globale.
- **Baseline + placeholders** — pas d'architecture, de modules ni de roadmap
  inventés ; tout est paramétré par `<PLACEHOLDER>`.
- **Windows d'abord** — permissions/hooks/scripts ciblent Windows ; le shell
  (Git Bash / PowerShell / cmd) est à finaliser à l'installation.

## Conventions
- **Commits :** [Conventional Commits](https://www.conventionalcommits.org/)
  (voir `CLAUDE.md` → Commit convention, via le skill `git-commit`).
- **Décidé par l'équipe (non imposé) :** le modèle de branches / workflow git.

## Documentation
- Installation → [`docs/INSTALL.md`](docs/INSTALL.md)
- Config Claude Code (permissions, hooks) → [`docs/CONFIG.md`](docs/CONFIG.md)
- Serveurs MCP → [`docs/MCP.md`](docs/MCP.md)
- Build & test → wrappers `scripts/` (résumé dans `CLAUDE.md`)
