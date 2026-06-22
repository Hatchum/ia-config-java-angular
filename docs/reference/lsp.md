# LSP — Code Intelligence

> Sources vérifiées : [Tools reference — LSP](https://code.claude.com/docs/en/tools-reference#lsp-tool-behavior) · [Code intelligence plugins](https://code.claude.com/docs/en/discover-plugins#code-intelligence) · Vérifié le 2026-06-22
> Issu de l'éclatement de `docs/TASK.md` (archivé — voir `../guide/roadmap.md`).

L'outil **`LSP`** donne à Claude une intelligence de code via un *language
server* : navigation au niveau des symboles et **diagnostics automatiques après
chaque édition** (erreurs de type, imports manquants…), sans lancer de
compilateur. Plus précis que grep/glob pour le code typé.

## ⚠️ Correction majeure vs TASK.md

> TASK.md proposait `ENABLE_LSP_TOOL: "1"` + un bloc `enabledPlugins` dans
> `settings.json`. **La doc officielle ne mentionne aucune variable
> `ENABLE_LSP_TOOL`.** L'outil LSP s'active **simplement en installant un plugin
> de code intelligence** pour le langage ; le binaire du language server
> s'installe **séparément**. Pas de config manuelle de `settings.json` requise.

## Installation

1. Installer le **plugin** (marketplace officiel, dispo par défaut) :
   ```
   /plugin install jdtls-lsp@claude-plugins-official        # Java
   /plugin install typescript-lsp@claude-plugins-official   # TypeScript
   ```
   (En ligne de commande : `claude plugin install <nom>@claude-plugins-official`.)
2. Installer le **binaire** du language server, présent dans le `$PATH`.

| Langage | Plugin | Binaire requis |
|---|---|---|
| Java | `jdtls-lsp` | `jdtls` |
| TypeScript | `typescript-lsp` | `typescript-language-server` |
| Python | `pyright-lsp` | `pyright-langserver` |
| Go | `gopls-lsp` | `gopls` |
| Rust | `rust-analyzer-lsp` | `rust-analyzer` |
| Kotlin | `kotlin-lsp` | `kotlin-language-server` |
| C/C++ | `clangd-lsp` | `clangd` |
| C# | `csharp-lsp` | `csharp-ls` |
| PHP | `php-lsp` | `intelephense` |
| Lua | `lua-lsp` | `lua-language-server` |
| Swift | `swift-lsp` | `sourcekit-lsp` |

> Si Claude détecte un binaire déjà installé, il peut proposer le plugin
> correspondant à l'ouverture du projet. Erreur `Executable not found in $PATH`
> dans l'onglet *Errors* de `/plugin` → installer le binaire.

> Note Windows : TASK.md suggérait `brew install jdtls` (macOS). Sur Windows,
> installer `jdtls` / `typescript-language-server` par un autre canal (téléchargement,
> npm pour TS : `npm i -g typescript-language-server typescript`).

## Vérifier

```bash
claude plugin list          # ou onglet « Installed » de /plugin
```

## Ce que Claude gagne

- **Diagnostics automatiques** : après chaque édition, le serveur signale erreurs
  et warnings ; Claude corrige dans le même tour. (Inline : **Ctrl+O** quand
  l'indicateur « diagnostics found » apparaît.)
- **Navigation** : aller à la définition, trouver les références, type au survol
  (hover), lister les symboles d'un fichier, chercher un symbole dans le
  workspace, trouver les implémentations, tracer les hiérarchies d'appels.

## Règles utiles (à mettre dans `~/.claude/CLAUDE.md` ou une rule)

```markdown
### Code Intelligence — préférer LSP à Grep/Glob/Read pour le code typé
- Aller à la source : définition / implémentation.
- Avant de renommer ou changer une signature : trouver d'abord les références.
- Grep/Glob uniquement pour le texte (commentaires, strings, config).
- Après modification : vérifier les diagnostics LSP avant de continuer.
```

## Dépannage

- **Serveur ne démarre pas** : binaire absent du `$PATH` (onglet *Errors* de `/plugin`).
- **Mémoire élevée** (`rust-analyzer`, `pyright` sur gros projets) : désactiver le
  plugin (`/plugin disable <nom>`) et revenir aux outils de recherche intégrés.
- **Faux positifs en monorepo** : imports internes non résolus si le workspace est
  mal configuré — n'affecte pas la capacité d'édition.
