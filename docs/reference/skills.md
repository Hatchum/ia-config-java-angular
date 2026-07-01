# Skills — `.claude/skills/`

> Source vérifiée : [Skills](https://code.claude.com/docs/en/skills) · Vérifié le 2026-06-22
> Issu de l'éclatement de `docs/TASK.md` (archivé — voir `../guide/roadmap.md`).

Un skill est un dossier contenant un `SKILL.md` (instructions + frontmatter
YAML). Le **corps** ne se charge qu'à l'usage (la **description** reste, elle, en
contexte à faible coût). Suit le standard ouvert [Agent Skills](https://agentskills.io).

> Note : les « custom commands » (`.claude/commands/*.md`) ont fusionné avec les
> skills. `.claude/commands/deploy.md` et `.claude/skills/deploy/SKILL.md` créent
> tous deux `/deploy`. Les skills sont recommandés (fichiers de support, etc.).

## Emplacements

| Niveau | Chemin | Portée |
|---|---|---|
| Enterprise | managed settings | Toute l'organisation |
| Personnel | `~/.claude/skills/<nom>/SKILL.md` | Tous vos projets |
| Projet | `.claude/skills/<nom>/SKILL.md` | Ce projet |
| Plugin | `<plugin>/skills/<nom>/SKILL.md` | Où le plugin est activé |

Priorité : enterprise > personnel > projet (> bundled). Le **nom de commande**
vient du **nom du dossier**, pas du champ `name` du frontmatter.

## Structure

```
mon-skill/
├── SKILL.md        # requis (garder < 500 lignes)
├── reference.md    # doc détaillée — chargée à la demande
├── examples.md     # exemples de sortie
└── scripts/
    └── helper.py   # exécuté, pas chargé en contexte
```

Référencer les fichiers de support depuis `SKILL.md` pour que Claude sache quoi
charger et quand.

## Frontmatter (référence officielle complète)

```yaml
---
name: mon-skill                 # optionnel (défaut = nom du dossier)
description: Ce que fait le skill et quand l'utiliser
when_to_use: phrases déclencheuses additionnelles
argument-hint: "[issue-number]"
arguments: [issue, branch]      # args nommés -> $issue, $branch
disable-model-invocation: true  # seul l'utilisateur l'invoque (/nom)
user-invocable: false           # seul Claude l'invoque (caché du menu /)
allowed-tools: Read Grep        # pré-autorisés sans prompt
disallowed-tools: AskUserQuestion
model: inherit                  # ou sonnet/opus/haiku/fable
effort: high                    # low|medium|high|xhigh|max
context: fork                   # exécute dans un subagent
agent: Explore                  # type de subagent si context: fork
paths: ["**/*.java"]            # active le skill selon les fichiers
shell: powershell               # bash (défaut) | powershell
hooks: { ... }                  # hooks scoppés au skill
---
```

> **Correction vs TASK.md** : il n'existe **pas** de champ `version` dans le
> frontmatter officiel. Seul `description` est *recommandé*, tous les champs sont
> optionnels. `description` + `when_to_use` sont tronqués à **1 536 caractères**
> dans le listing → mettre le cas d'usage clé en premier.

### Contrôle de l'invocation

| Frontmatter | Vous | Claude | Description en contexte |
|---|---|---|---|
| (défaut) | oui | oui | oui (corps chargé à l'invocation) |
| `disable-model-invocation: true` | oui | non | non |
| `user-invocable: false` | non | oui | oui |

## Injection de contexte dynamique

```markdown
## Changements
!`git diff HEAD`
```

La commande `` !`cmd` `` est exécutée **avant** que Claude voie le contenu ; sa
sortie remplace la ligne. Bloc multi-lignes : ouvrir avec ` ```! `. Inline
reconnu seulement en début de ligne ou après un espace.

## Arguments

`$ARGUMENTS` (tout), `$ARGUMENTS[N]` / `$N` (par position), `$nom` (args
nommés). Variables : `${CLAUDE_SESSION_ID}`, `${CLAUDE_SKILL_DIR}`,
`${CLAUDE_EFFORT}`.

## Cycle de vie

Une fois invoqué, le `SKILL.md` rendu **reste en contexte** tout le reste de la
session (coût récurrent → corps concis). Après compaction, les 5 000 premiers
tokens de chaque skill récent sont réattachés (budget combiné 25 000 tokens).

## Skills bundlés (natifs)

`/code-review`, `/batch`, `/debug`, `/loop`, `/claude-api`, `/run`, `/verify`,
`/run-skill-generator`. Désactivables via `disableBundledSkills`.

## Skills à créer (roadmap projet, repris de TASK.md)

- **`prompt-creator`** — meta-prompting (déjà présent dans ce dépôt).
- **`skill-claude-memory`** — doc CLAUDE.md / rules.
- **`skill-subagent-creator`** — cf. skill `subagent-creator` existant.
- **`skill-hook-creator`** — templates de [hooks](hooks.md).
- ~~**`workflow-dev` / `workflow-debug`**~~ — ✅ **créés** (pattern
  fichiers-étapes, rebaptisés `feature` / `bugfix` pour interface utilisateur),
  voir [`workflows.md`](workflows.md) et
  [`docs/research/agentique.md`](../research/agentique.md) pour la
  conception (rôles, SOP paramétrables, HITL) et les fichiers réels sous
  `.ai/skills/feature/` et `.ai/skills/bugfix/`.

## Évaluer un skill

Plugin officiel `skill-creator` (`/plugin install skill-creator@claude-plugins-official`) :
test cases (`evals/evals.json`), runs isolés en subagent, grading, benchmark
with/without skill, A/B de versions, tuning de description. `/doctor` indique si
des descriptions sont tronquées.

## Règles d'or

- **Description précise et distinctive** : c'est ce qui décide du chargement.
- `SKILL.md` < 500 lignes ; déplacer le détail dans des fichiers de support.
- `disable-model-invocation: true` pour tout ce qui a des effets de bord (deploy…).
- `context: fork` pour isoler dans un subagent (cf. [subagents.md](subagents.md)).
