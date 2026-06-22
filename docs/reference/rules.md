# Rules — `.claude/rules/`

> Source vérifiée : [Memory — Organize rules](https://code.claude.com/docs/en/memory#organize-rules-with-claude/rules/) · Vérifié le 2026-06-22
> Issu de l'éclatement de `docs/TASK.md` (archivé — voir `../guide/roadmap.md`).

Les rules permettent de **découper CLAUDE.md en fichiers modulaires**, et surtout
de **path-scoper** des instructions (actives seulement sur certains fichiers) →
économie de contexte.

## Structure

```
.claude/
  rules/
    code-style.md        # un sujet par fichier
    testing.md
    security.md
	java-conventions.md      # Actif uniquement sur les fichiers Java
    angular-conventions.md   # Actif uniquement sur les composants Angular
    test-conventions.md      # Actif uniquement sur les fichiers de test
    frontend/            # sous-dossiers OK (découverte récursive)
      angular.md
```

Tous les `.md` sont découverts récursivement. Nom de fichier descriptif, **un
sujet par fichier**.

## Path-scoping (frontmatter `paths`)

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "**/*.{ts,tsx}"
---

# Règles API
- Toujours valider les entrées
- Format d'erreur standard
```

- Une rule **avec** `paths` ne se charge que quand Claude **lit un fichier
  correspondant** au glob (pas à chaque tool use).
- Une rule **sans** `paths` est chargée **inconditionnellement au lancement**,
  avec la même priorité que `.claude/CLAUDE.md`.

### Patterns glob

| Pattern | Correspond à |
|---|---|
| `**/*.java` | Tous les `.java`, n'importe quelle profondeur |
| `src/**/*` | Tout sous `src/` |
| `*.md` | Markdown à la racine du projet |
| `src/**/*.{ts,tsx}` | Brace expansion : `.ts` et `.tsx` |

## Rules utilisateur

`~/.claude/rules/` s'applique à **tous** les projets de la machine. Chargées
**avant** les rules projet (donc les rules projet ont une priorité supérieure).

## Partage par symlink

Le dossier `.claude/rules/` supporte les symlinks (les boucles sont détectées) :

```bash
ln -s ~/shared-claude-rules .claude/rules/shared
ln -s ~/company-standards/security.md .claude/rules/security.md
```

## Application dans ce projet (rappel CLAUDE.md)

| Rule | Scope `paths` |
|------|---------------|
| `.claude/rules/java-coding-rules.md` | `**/*.java` |
| `.claude/rules/angular-coding-rules.md` | `**/*.ts`, `**/*.scss`, `**/*.component.html` |

## Rules vs Skills

Une **rule** est chargée en contexte (à chaque session, ou à l'ouverture de
fichiers correspondants) : pour des **faits** à respecter en permanence. Un
[**skill**](skills.md) ne se charge **qu'à l'invocation** : pour des procédures
ponctuelles. Si une instruction n'a pas besoin d'être en permanence en
contexte, en faire un skill.
