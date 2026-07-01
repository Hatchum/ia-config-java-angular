# INSTALL — intégrer ce kit dans un monorepo Java + Angular existant (Windows)

Ce dépôt est un **kit de configuration Claude Code portable**, pas un projet.
L'installer consiste à le copier dans un monorepo Maven multi-modules existant
(POM parent + modules Java + un module Angular), puis à remplir les placeholders
en lisant le vrai code. Il ne dépend d'**aucune** config personnelle/globale.

## 1. Copier ceci à la racine du dépôt cible
```
AGENTS.md             (SOURCE unique des instructions — lue nativement par Codex)
CLAUDE.md             ("@AGENTS.md" + couche spécifique Claude Code)
ARCHITECTURE.md
.gitignore            (à fusionner avec le .gitignore existant du projet)
.ai/                  (dossier CANONIQUE : skills/ + rules/ + config/ — la seule vraie copie)
.claude/              (settings.json GÉNÉRÉ, hooks/, agents/ ; skills + rules = liens vers .ai/)
.agents/              (skills = lien vers .ai/skills — découverte côté Codex)
.codex/               (config.toml, hooks.json, rules/ — GÉNÉRÉS par sync-config)
scripts/              (wrappers build/test + générateur sync-config.*)
skills-lock.json      (suit la source amont des skills Angular)
frontend/             (module Angular placeholder : CLAUDE.md per-module +
                       .claude/skills/ en symlinks vers .ai/skills/angular-* —
                       à renommer/déplacer vers le vrai module)
docs/                 (guide/config.md = référence utile dans la cible ;
                       guide/install.md optionnel ; docs/research/ = artefacts
                       internes du kit, ne pas copier)
```
> **Ne PAS copier `README.md`** : c'est la page d'accueil du *kit*, il écraserait
> le `README.md` du projet cible.
>
> **MCP retiré** : les outils externes sont couverts par des skills invoquant
> leur CLI (`find-docs`/ctx7, `playwright`, `api-testing`). `docs/guide/mcp.md`
> n'est conservé qu'à titre historique — aucun `.mcp.json` à copier.
>
> Sous Windows, préserver les symlinks avec `git config --global core.symlinks true`
> avant le clone/la copie, ou les convertir en copies réelles (§5). Les liens de
> dossiers (`.claude/skills`, `.claude/rules`, `.agents/skills`) peuvent aussi être
> posés en junctions : `cmd /c mklink /J .claude\skills .ai\skills` (idem rules/agents).
>
> Après copie et remplissage des placeholders, régénérer le résiduel par-outil :
> `scripts\sync-config.ps1` (valide `.ai/config/*.yaml`, régénère `settings.json`
> + `.codex/*`, projette le bloc ROLE BINDING dans `.claude/agents/*.md`).

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
| `<VERIFY_COMMANDS>` | `.claude/hooks/lib/checks.sh` / `checks.ps1` | La commande de gate build/tests du hook `verify-on-stop` (§4) — ex. `mvn -q test` |
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

## 4. Activer les linters et la gate de fin de session
Les hooks sont livrés **inertes** (toute commande contenant encore `<` est
ignorée, exit 0). Pour activer :
- **Lint** : remplir `JAVA_LINT_CMD` / `WEB_LINT_CMD` dans
  `.claude/hooks/lib/checks.sh` (et/ou `checks.ps1`) avec les linters/
  formatters existants du projet.
- **Gate de fin de session** (`verify-on-stop`) : remplir `VERIFY_CMD` /
  `$VerifyCmd` au même endroit (ex. `mvn -q test`) — le hook `Stop` bloque
  alors la fin d'une session sur un worktree modifié tant que cette commande
  échoue (protection anti-boucle via `stop_hook_active`).

Détails dans `docs/guide/config.md`.

## 5. Disposition des skills (source unique `.ai/skills/`)
La **seule vraie copie** de tous les skills vit dans `.ai/skills/` (un dossier
par skill, chacun avec un `SKILL.md`). Le reste n'est que des liens :
- **Racine (les deux agents)** → `.claude/skills` et `.agents/skills` sont des
  liens (symlink/junction) vers `.ai/skills/`.
- **Skills Angular (per-module)** → `<angular-module>/.claude/skills/`. Dans le
  kit, le placeholder `frontend/.claude/skills/` contient des **symlinks** vers
  `.ai/skills/angular-developer` et `.ai/skills/angular-new-app` (source amont
  suivie par `skills-lock.json` à la racine). Ils sont découverts à la demande
  quand Claude travaille sur des fichiers du module.

Pour finaliser :
- **Symlinks Windows.** Soit exécuter `git config --global core.symlinks true`
  (+ mode Développeur / admin) avant le clone pour que les symlinks se
  matérialisent, **soit** poser des junctions (`mklink /J`, aucun droit requis)
  pour les liens de dossiers, **soit** remplacer chaque lien par une copie
  réelle du dossier source correspondant dans `.ai/skills/` (on perd la source
  unique, mais c'est increvable sur n'importe quel poste Windows).
- **Déplacer les skills Angular vers le vrai module Angular.** Si le module ne
  s'appelle pas `frontend`, déplacer `frontend/.claude/skills/` dans le répertoire
  réel du module (garder les cibles relatives des symlinks vers `.ai/skills/`
  à la racine, ou les re-pointer) et supprimer le placeholder `frontend/`. Garder
  `ANGULAR_DIR` (scripts) cohérent.
- L'équipe ajoute ses propres skills dans `.ai/skills/` (vus par les deux
  agents). Les skills livrés peuvent rester ou être remplacés.

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
