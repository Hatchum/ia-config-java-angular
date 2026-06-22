# Hooks — `.claude/settings.json`

> Sources vérifiées : [Hooks guide](https://code.claude.com/docs/en/hooks-guide) · [Hooks reference](https://code.claude.com/docs/en/hooks) · Vérifié le 2026-06-22
> Issu de l'éclatement de `docs/TASK.md` (archivé — voir `../guide/roadmap.md`).

Les hooks sont des commandes shell **déterministes** exécutées à des points
précis du cycle de vie. Contrairement à CLAUDE.md (advisory), un hook
**garantit** l'action. Configurer dans un fichier de settings ; `/hooks` ouvre
un navigateur **en lecture seule** (l'édition se fait dans le JSON).

## Structure JSON

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "./scripts/security-check.sh" }]
      }
    ]
  }
}
```

- Chaque nom d'événement est une **clé** dans l'unique objet `hooks`.
- `matcher` : nom d'outil (`Edit|Write`, `Bash`…) ; vide = tous. Les matchers
  utilisent les **noms d'outils nus** (pas le format `Tool(spec)`).
- Sur Windows : ajouter `"shell": "powershell"` à l'entrée du hook et écrire le
  script en PowerShell.
- L'input est passé en **JSON sur stdin** (extraire avec `jq`).

## Événements (liste complète)

> **Correction vs TASK.md** : il existe bien plus que 4 événements. Les plus
> utiles d'abord, puis la liste exhaustive.

### Principaux
| Événement | Quand | Blocage (exit 2) |
|---|---|---|
| `PreToolUse` | Avant l'exécution d'un outil | Bloque l'outil |
| `PostToolUse` | Après succès d'un outil | stderr montré (outil déjà exécuté) |
| `PostToolUseFailure` | Après échec d'un outil | stderr montré |
| `UserPromptSubmit` | Soumission d'un prompt | Bloque le prompt |
| `SessionStart` | Début/reprise de session | Ne peut bloquer ; stdout = contexte |
| `SessionEnd` | Fin de session | Exit code ignoré (cleanup) |
| `Stop` | Claude finit de répondre | Empêche l'arrêt (continue) |
| `SubagentStart` / `SubagentStop` | Début/fin d'un subagent | `SubagentStop` peut empêcher l'arrêt |
| `Notification` | Claude attend une entrée/permission | Exit code ignoré |
| `PreCompact` / `PostCompact` | Avant/après compaction | `PreCompact` peut bloquer |

### Autres événements disponibles
`Setup`, `UserPromptExpansion`, `PermissionRequest`, `PermissionDenied`,
`PostToolBatch`, `MessageDisplay`, `TaskCreated`, `TaskCompleted`,
`StopFailure`, `TeammateIdle`, `InstructionsLoaded` (log des fichiers
CLAUDE.md/rules chargés — utile au debug), `ConfigChange`, `CwdChanged`,
`FileChanged`, `WorktreeCreate`, `WorktreeRemove`, `Elicitation`,
`ElicitationResult`.

### Matchers de `Notification`
`permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`,
`elicitation_complete`, `elicitation_response`.

## Codes de sortie

- **Exit 0** : succès. Le stdout JSON est parsé pour décisions/contexte.
- **Exit 2** : erreur **bloquante**. stderr renvoyé à Claude ou montré à
  l'utilisateur. L'effet dépend de l'événement (bloque l'outil, refuse la
  permission, empêche l'arrêt…).
- **Autre (1, 3+)** : erreur non bloquante. 1re ligne de stderr en transcript,
  stderr complet en debug log ; l'exécution continue.

## Hooks scoppés (skills / subagents)

Un hook peut aussi être défini dans le frontmatter d'un [skill](skills.md) ou
d'un [subagent](subagents.md) : il ne vit alors que pendant l'activité de
celui-ci. Dans un subagent, un `Stop` en frontmatter devient `SubagentStop`.

## Hooks à créer (roadmap projet, repris de TASK.md)

- [ ] **Validation TypeScript** : `PostToolUse` sur `Edit|Write` → `tsc --noEmit`.
- [ ] **Validation Java** : `PostToolUse` → compilation / build tool.
- [ ] **Blocage migrations** : `PreToolUse` sur `Write` → exit 2 si chemin migrations.
- [ ] **ESLint/Prettier** : `PostToolUse` sur `Edit|Write` → auto-formatage.

> Astuce : Claude sait écrire un hook pour vous — « Écris un hook qui lance
> eslint après chaque édition ». Le skill `update-config` aide à configurer
> `settings.json`.

> 💡 « Ne jamais modifier `.env` » dans CLAUDE.md est une *requête* ; un
> `PreToolUse` qui exit 2 est une *garantie*.
