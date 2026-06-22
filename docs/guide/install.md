# INSTALL — intégrer ce kit dans un monorepo Java + Angular existant (Windows)

Ce dépôt est un **kit de configuration Claude Code portable**, pas un projet.
L'installer consiste à le copier dans un monorepo Maven multi-modules existant
(POM parent + modules Java + un module Angular), puis à remplir les placeholders
en lisant le vrai code. Il ne dépend d'**aucune** config personnelle/globale.

## 1. Copier ceci à la racine du dépôt cible
```
CLAUDE.md
ARCHITECTURE.md
.gitignore            (à fusionner avec le .gitignore existant du projet)
.claude/              (settings.json, rules/, hooks/, skills/  ← skills Java + méta : find-docs, prompt-creator, skill-creator, subagent-creator)
scripts/              (wrappers build/test)
.agents/              (source des skills Angular, gérée par l'installeur)
skills-lock.json      (suit la source amont des skills Angular)
frontend/             (module Angular placeholder : .claude/skills/ ← skills Angular,
                       en symlinks vers .agents/ — à renommer/déplacer vers le vrai module)
.mcp.json             (serveur GitLab via la CLI glab ; prérequis : glab + glab auth login — voir docs/guide/mcp.md)
docs/                 (guide/config.md + guide/mcp.md = référence utile dans la cible ;
                       guide/install.md optionnel ; research/subagent-creator-*.md = artefacts internes du kit, ne pas copier)
```
> **Ne PAS copier `README.md`** : c'est la page d'accueil du *kit*, il écraserait
> le `README.md` du projet cible.
>
> MCP est **optionnel** : `.mcp.json` déclare le serveur **GitLab** (`glab mcp serve`,
> approuvé au premier usage). Alternatives documentées dans `docs/guide/mcp.md`
> (GitLab Duo hébergé, GitHub MCP). Le supprimer si l'équipe n'en veut pas.
>
> Sous Windows, préserver les symlinks avec `git config --global core.symlinks true`
> avant le clone/la copie, ou les convertir en copies réelles (§5).

## 2. Remplir les placeholders
Lire le vrai POM parent, l'arborescence des modules et le `package.json` pour
résoudre chacun.

| Placeholder | Où | Comment le déterminer |
|-------------|-----|------------------------|
| `<PROJECT_NAME>` | `CLAUDE.md`, `ARCHITECTURE.md` | Le nom du dépôt / produit |
| `<TEAM_LANGUAGE>` | `CLAUDE.md` (Working style) | La langue de travail de l'équipe |
| `<JAVA_VERSION>` | `CLAUDE.md` | `maven.compiler.release` / toolchain dans le POM |
| `<FRAMEWORK>` | `CLAUDE.md` | Spring Boot / Quarkus / Jakarta / plain (deps du POM) |
| `<ANGULAR_VERSION>` | `CLAUDE.md` | `@angular/core` dans le `package.json` du module Angular |
| `<MODULE_LIST>` | `CLAUDE.md`, `ARCHITECTURE.md` | `<modules>` dans le POM parent |
| `<ARCHITECTURE>` | `CLAUDE.md` | Résumé d'une ligne pointant vers `ARCHITECTURE.md` |
| `<PARENT_POM_ARTIFACT>` | `ARCHITECTURE.md` | `artifactId` du POM parent |
| Responsabilités / deps / flux des modules | `ARCHITECTURE.md` §1–5 | Le vrai graphe des modules (sans cycle) |
| `<LINT_COMMANDS>` | `.claude/hooks/lib/checks.sh` / `checks.ps1` | Les vraies commandes de lint/format du projet (§4) |
| `ANGULAR_DIR` / `$AngularDir` | `scripts/test.cmd` / `test.ps1` | Le répertoire du module Angular (défaut `frontend`) |
| Répertoire du module Angular (`frontend`) | dossier `frontend/`, `frontend/CLAUDE.md`, `ANGULAR_DIR` (scripts) | Si le module Angular ne s'appelle pas `frontend`, renommer le dossier en conséquence. La rule Angular est **scopée par contenu** (`*.ts` / `*.scss` / `*.component.html`), donc aucun edit nécessaire |

## 3. Finaliser ce qui dépend du shell
Le kit est volontairement **large** car le shell de l'équipe (Git Bash /
PowerShell / cmd) n'est pas encore figé. Une fois fixé :
- **Hooks :** garder soit la variante `.sh`, soit la `.ps1`, et mettre à jour
  chaque entrée dans `.claude/settings.json` (`"shell"` + `command`) ; supprimer
  la variante inutilisée. Voir `docs/guide/config.md` → « Basculer bash ↔ PowerShell ».
- **Permissions :** resserrer les patterns `deny` volontairement larges (ex.
  `Remove-Item *`) vers le shell choisi.

## 4. Activer les linters
Les hooks sont livrés **inertes** (toute commande contenant encore `<` est
ignorée, exit 0). Pour activer le lint, remplir `JAVA_LINT_CMD` / `WEB_LINT_CMD`
dans `.claude/hooks/lib/checks.sh` (et/ou `checks.ps1`) avec les linters/
formatters existants du projet. Détails dans `docs/guide/config.md`.

## 5. Disposition des skills (groupés par stack)
Les skills sont séparés par stack selon le pattern monorepo de Claude Code — un
dossier par skill, chacun avec un `SKILL.md` :
- **Skills Java** → `.claude/skills/` à la racine (vrais dossiers).
- **Skills Angular** → `<angular-module>/.claude/skills/`. Dans le kit ils sont
  dans le placeholder `frontend/.claude/skills/`, sous forme de **symlinks** vers
  la source gérée par l'installeur `.agents/skills/` (suivie par `skills-lock.json`
  à la racine) : l'installeur peut donc les mettre à jour sans duplication. Ils
  sont découverts à la demande quand Claude travaille sur des fichiers du module.

Pour finaliser :
- **Symlinks Windows.** Soit exécuter `git config --global core.symlinks true`
  (+ mode Développeur / admin) avant le clone pour que les symlinks se
  matérialisent, **soit** remplacer chaque lien de `frontend/.claude/skills/` par
  une copie réelle du dossier source correspondant dans `.agents/skills/` (on perd
  la mise à jour auto par l'installeur, mais c'est increvable sur n'importe quel
  poste Windows).
- **Déplacer les skills Angular vers le vrai module Angular.** Si le module ne
  s'appelle pas `frontend`, déplacer `frontend/.claude/skills/` dans le répertoire
  réel du module (garder les cibles relatives des symlinks vers `.agents/skills/`
  à la racine, ou les re-pointer) et supprimer le placeholder `frontend/`. Garder
  `ANGULAR_DIR` (scripts) cohérent.
- L'équipe ajoute ses propres skills au bon endroit (Java à la racine, Angular
  dans le module). Les skills livrés peuvent rester ou être remplacés.

## 6. Vérifier
Depuis la racine du dépôt, lancer les wrappers et confirmer que les deux passent
au vert :
```
scripts\build.cmd      (ou scripts\build.ps1)
scripts\test.cmd       (ou scripts\test.ps1)
```

## Conventions
- **Messages de commit :** le kit adopte [Conventional Commits](https://www.conventionalcommits.org/)
  (voir `CLAUDE.md` → Commit convention, appliqué via le skill `git-commit`).
- **Hors-scope :** le **modèle de branches / workflow git** reste décidé par
  l'équipe — le kit n'en impose aucun. Ne pas en ajouter ici.
