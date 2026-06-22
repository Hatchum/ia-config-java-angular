# Fondation — CLAUDE.md

> Source vérifiée : [Memory / CLAUDE.md](https://code.claude.com/docs/en/memory) · Vérifié le 2026-06-22
> Issu de l'éclatement de `docs/TASK.md` (archivé — voir `../guide/roadmap.md`).

Le fichier `CLAUDE.md` est lu **au début de chaque session**. Contrairement à
une croyance répandue, il est **chargé en entier quelle que soit sa longueur** —
mais les fichiers longs réduisent l'adhérence de Claude. C'est du **contexte**
livré comme message utilisateur après le system prompt, pas une configuration
imposée. Pour une garantie d'exécution, utiliser un [hook](hooks.md).

## Hiérarchie des fichiers (ordre de chargement, du plus large au plus précis)

| Portée | Emplacement | Usage |
|---|---|---|
| **Managed policy** (org) | macOS `/Library/Application Support/ClaudeCode/CLAUDE.md` · Linux/WSL `/etc/claude-code/CLAUDE.md` · Windows `C:\Program Files\ClaudeCode\CLAUDE.md` | Règles d'entreprise, non désactivables |
| **User** | `~/.claude/CLAUDE.md` | Préférences personnelles, tous projets |
| **Project** | `./CLAUDE.md` **ou** `./.claude/CLAUDE.md` | Conventions d'équipe (versionné git) |
| **Local** | `./CLAUDE.local.md` | Overrides perso (à mettre dans `.gitignore`) |
| **Sous-dossier** | `./src/CLAUDE.md` | Chargé **à la demande** quand Claude lit un fichier de ce répertoire |

> Correction vs TASK.md : le project CLAUDE.md peut aussi vivre dans
> `./.claude/CLAUDE.md`. Il existe aussi un niveau **managed policy** (org-wide).

**Ordre de chargement** : Claude remonte l'arborescence depuis le répertoire
courant. Tous les fichiers découverts sont **concaténés** (pas d'écrasement), de
la racine vers le répertoire de travail. Dans un dossier, `CLAUDE.local.md` est
ajouté après `CLAUDE.md`.

## Imports `@path`

```markdown
See @README.md for overview and @package.json for npm commands.
- git workflow @docs/git-instructions.md
- @~/.claude/my-project-instructions.md
```

- Chemins relatifs (résolus par rapport au fichier qui importe) ou absolus.
- Imports récursifs : **profondeur max 4 sauts**.
- Pour citer un chemin sans l'importer, l'entourer de backticks (`` `@README` ``).
- Les imports dans des blocs de code ne sont pas suivis.

## Pattern AGENTS.md (utilisé par ce projet)

Claude Code lit `CLAUDE.md`, **pas** `AGENTS.md`. Pour partager les instructions
avec d'autres agents (Codex…), on importe :

```markdown
@AGENTS.md

## Claude Code
Instructions spécifiques Claude ici.
```

(C'est exactement le montage de ce dépôt.) Sur Windows, préférer l'import
`@AGENTS.md` au symlink (qui demande des privilèges admin).

## Que mettre / ne pas mettre

| ✅ Inclure | ❌ Exclure |
|---|---|
| Commandes Bash que Claude ne peut deviner | Ce que Claude déduit du code |
| Conventions de style ≠ des défauts | Conventions standard du langage |
| Instructions de test / test runners | Doc d'API détaillée (mettre un lien) |
| Étiquette repo (branches, PR) | Infos qui changent souvent |
| Décisions d'archi spécifiques | Description fichier par fichier |
| Quirks d'env (env vars requises) | Évidences ("écrire du code propre") |

## Règles d'or

- **Cibler < 200 lignes** par fichier CLAUDE.md (au-delà : adhérence dégradée).
- Pour chaque ligne : *« Sa suppression ferait-elle faire des erreurs à Claude ? »* Si non → supprimer.
- Émphase `IMPORTANT:` / `YOU MUST` pour les règles critiques.
- Versionner dans git ; le fichier prend de la valeur avec le temps.
- Au-delà : découper en [rules path-scopées](rules.md) ou en [skills](skills.md).
- Commentaires HTML de bloc (`<!-- … -->`) : retirés du contexte (notes pour humains gratuites).
- Survie à `/compact` : le CLAUDE.md racine est re-injecté ; les CLAUDE.md de sous-dossiers non.

## Outils

- `/init` génère un CLAUDE.md de départ (lit aussi un `AGENTS.md`/`.cursorrules` existant).
- `/memory` liste les fichiers CLAUDE.md / rules chargés et permet de les éditer.

## À ne pas confondre — Auto memory

Système **distinct** : `~/.claude/projects/<project>/memory/` (`MEMORY.md` +
fichiers thématiques) que **Claude** écrit lui-même. Seules les 200 premières
lignes / 25 Ko de `MEMORY.md` sont chargées par session. Toggle via `/memory`
ou `autoMemoryEnabled`. (Voir le répertoire memory de ce projet.)
