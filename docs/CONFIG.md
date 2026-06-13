# Config Claude Code — permissions & hooks (référence)

Aide-mémoire **humain** pour tout ce qui se trouve sous `.claude/` dans ce kit.
Pour *ce qu'il faut remplir lors de l'installation dans un projet*, voir
`INSTALL.md`.

## Arborescence
```
.claude/
├── settings.json     # base des permissions + déclarations des hooks
├── rules/            # loi de codage path-scopée (Java, Angular) via le frontmatter `paths`
├── skills/           # connaissance à la demande — skills JAVA (niveau racine)
└── hooks/            # hooks lint/format + changelog (bash + PowerShell)
```
> Les **skills Angular** vivent avec le module Angular dans
> `<angular-module>/.claude/skills/` (placeholder `frontend/.claude/skills/`),
> pas à la racine — le pattern monorepo les découvre à la demande quand tu
> travailles dans ce module. Ce sont des **symlinks** vers la source gérée par
> l'installeur `.agents/skills/` (`skills-lock.json` à la racine). Sous Windows,
> activer `git config core.symlinks true` avant le clone, ou les convertir en
> copies réelles à l'installation — voir `INSTALL.md` §5.

## Permissions (`settings.json`)
> **Lancer Claude depuis la racine du dépôt.** Le `settings.json` projet
> (permissions + hooks) ne se charge que depuis ton répertoire de lancement et
> n'est *pas* hérité des parents — démarrer dans `frontend/` ignorerait les
> hooks/permissions de la racine.

Précédence **deny > ask > allow**.
- **deny :** commandes destructrices Windows/PowerShell/cmd (`rm -rf`, `del /s`,
  `Remove-Item *`, `format`, `shutdown`, `taskkill /f`, `runas`, …).
- **ask :** git réécrivant l'historique / perdant des données (`push --force`,
  `reset --hard`, `clean`).
- **allow :** wrappers Maven/Gradle et git en lecture seule, plus
  `git commit`/`push`.

> ⚠️ **Shell non figé.** Les patterns couvrent Git Bash + PowerShell + cmd,
> certains sont donc volontairement larges (ex. `Remove-Item *` bloque même la
> suppression d'un seul fichier). **Resserrer une fois le shell de l'équipe
> fixé.** Pas de `trash` natif sous Windows ; une suppression sûre via la
> Corbeille pourra être ajoutée plus tard.

## Hooks (`hooks/`)
Chaque hook lit le JSON de l'événement sur **stdin** et signale via le code de
sortie (**exit 2 = signal bloquant ; son stderr est renvoyé à Claude**). Une
variante `.sh` (bash) **et** une `.ps1` (PowerShell) sont livrées pour chaque hook.

| Hook | Événement / matcher | Rôle |
|------|---------------------|------|
| `lint-format` | PostToolUse · `Write\|Edit\|MultiEdit` | Lint/formate le fichier touché (Java → outillage Java ; TS/HTML/SCSS/CSS → ESLint/Prettier). En cas d'échec, exit 2 renvoie la sortie du linter à Claude pour correction. |
| `log-changes` | PostToolUse · `Write\|Edit\|MultiEdit` | Ajoute `timestamp · outil · fichier` à `.claude/changes.local.log` (gitignoré). Ne bloque jamais. |
| `pre-commit-lint` | PreToolUse · `Bash` | Si la commande est un `git commit`, lint les fichiers indexés ; exit 2 **bloque** le commit. |

Logique partagée (propriétaire unique) :
- `lib/json.sh` / `lib/json.ps1` — extrait un champ du JSON de l'événement
  (jq si présent, sinon repli grep / `ConvertFrom-Json` en PowerShell).
- `lib/checks.sh` / `lib/checks.ps1` — routage **et seul endroit où vivent les
  commandes de lint** (les placeholders `<LINT_COMMANDS>`).

### Configurer les linters (requis pour activer le lint)
Les hooks sont livrés **inertes et sûrs** : tant que les commandes ne sont pas
remplies, toute commande contenant encore `<` est considérée *non configurée* et
le hook **skippe (exit 0)** — aucune erreur, aucun blocage. Pour activer :
1. Éditer `hooks/lib/checks.sh` (bash) et/ou `hooks/lib/checks.ps1` (PowerShell).
2. Remplacer `JAVA_LINT_CMD` / `WEB_LINT_CMD` (`$JavaLintCmd` / `$WebLintCmd`) par
   les vraies commandes du projet. Le fichier touché est disponible via `$FILE`
   (bash) ou `$file` (PowerShell). Exemples :
   - Java : `mvn -q -pl :your-module spotless:apply checkstyle:check`
   - Web : `npx eslint --fix "$FILE" && npx prettier --write "$FILE"`
3. Toujours invoquer les linters/formatters existants du projet — pas de
   vérifications regex maison.

### Basculer bash ↔ PowerShell
`settings.json` déclare la variante **bash** par défaut (`"shell": "bash"`,
appelant les fichiers `.sh` — nécessite Git for Windows). Pour exécuter la
variante PowerShell à la place, dans chaque entrée de hook mettre
`"shell": "powershell"` et pointer `command` vers le `.ps1` correspondant, ex. :
```json
{ "type": "command", "shell": "powershell",
  "command": "powershell -NoProfile -File \"%CLAUDE_PROJECT_DIR%\\.claude\\hooks\\lint-format.ps1\"" }
```
Finaliser ce choix une fois le shell de l'équipe fixé, puis supprimer la variante
inutilisée.

### Dépendances
- variante bash : Git for Windows (Git Bash) ; `jq` optionnel (repli grep sinon).
- variante PowerShell : Windows PowerShell / PowerShell 7 (`ConvertFrom-Json` est
  intégré). Aucune installation supplémentaire.

## Artefacts locaux (gitignorés)
- `.claude/changes.local.log` — journal de changements append-only de `log-changes`.
- `.claude/settings.local.json` — overrides personnels par machine, le cas échéant.

## Build & test
Les wrappers sont dans `scripts/` (`build.cmd`/`.ps1`, `test.cmd`/`.ps1`) :
`mvn -q -T1C clean install` pour le build, `mvn test` + `npm test` (module Angular)
pour les tests. Ce sont le critère de sortie « build & tests au vert ».
