# Recherche — Création de subagents (Anthropic + OpenAI)

> Synthèse documentaire servant de fondation au skill `subagent-creator`.
> Réalisée le 2026-06-17 via `find-docs` (Context7) et recherche web.
> **Toutes les affirmations ci-dessous proviennent de sources officielles** (voir
> § Sources). Pas de repli silencieux sur des connaissances d'entraînement.

## 1. Portée

Le futur skill `subagent-creator` cible la création de **Claude Code subagents**
(fichiers Markdown `.claude/agents/*.md`), **enrichis** des principes de
conception d'agents publiés par OpenAI (Agents SDK / *A practical guide to
building agents*). Anthropic = format et mécanique de référence ; OpenAI =
validation croisée des bonnes pratiques de conception.

## 2. Ce qu'est un Claude Code subagent

Un subagent est un assistant spécialisé qui s'exécute **dans sa propre fenêtre de
contexte**, avec un **prompt système dédié**, un **accès outils restreint** et des
permissions propres. Quand une tâche correspond à la `description` d'un subagent,
Claude **délègue** : le subagent travaille isolément et **ne renvoie qu'un
résumé**. Bénéfices officiels : préserver le contexte, imposer des contraintes
d'outils, réutiliser des configs, spécialiser le comportement, **maîtriser les
coûts** en routant vers un modèle plus rapide/économique (ex. Haiku).

**Format du fichier** : YAML frontmatter (config) + corps Markdown (= prompt
système). Le subagent ne reçoit **que** ce prompt système (plus l'environnement de
base : working dir, CLAUDE.md, git status), **pas** le system prompt complet de
Claude Code.

Emplacements (priorité décroissante) : managed settings → `--agents` CLI →
`.claude/agents/` (projet) → `~/.claude/agents/` (user) → plugin `agents/`.
L'identité vient **uniquement** du champ `name` (pas du nom de fichier ni du
sous-dossier). Recharge au démarrage de session si édité sur disque.

## 3. Champs du frontmatter (référence Anthropic)

| Champ | Requis | Rôle | Valeurs / défaut |
|-------|--------|------|------------------|
| `name` | **Oui** | Identifiant unique, déclencheur d'invocation | minuscules + tirets |
| `description` | **Oui** | **Quand** Claude doit déléguer (mécanisme de routage) | phrase claire ; ajouter « use proactively » pour pousser la délégation |
| `tools` | Non | Allowlist d'outils | hérite de tout si omis |
| `disallowedTools` | Non | Denylist (appliquée avant `tools`) | — |
| `model` | Non | **Modèle du subagent** | `sonnet` · `opus` · `haiku` · `fable` · ID complet (`claude-opus-4-8`) · `inherit` — **défaut `inherit`** |
| `permissionMode` | Non | Mode de permission | `default`/`acceptEdits`/`auto`/`dontAsk`/`bypassPermissions`/`plan` |
| `maxTurns` | Non | Plafond de tours agentiques | — |
| `skills` | Non | Skills préchargés dans le contexte | contenu complet injecté |
| `mcpServers` | Non | Serveurs MCP scoping subagent | inline ou référence |
| `hooks` | Non | Hooks de cycle de vie (PreToolUse, PostToolUse, Stop) | — |
| `memory` | Non | Mémoire persistante cross-session | `user`/`project`/`local` |
| `background` | Non | Exécuter en tâche de fond | défaut `false` |
| `effort` | Non | Niveau d'effort | `low`…`max` |
| `isolation` | Non | Worktree git isolé | `worktree` |
| `color` | Non | Couleur d'affichage | red/blue/green/… |
| `initialPrompt` | Non | 1er tour auto en mode `--agent` | — |

> Le corps Markdown (après le frontmatter) = **prompt système** du subagent.

### Résolution du modèle (ordre de priorité)
1. env `CLAUDE_CODE_SUBAGENT_MODEL` → 2. paramètre `model` par invocation →
3. `model` du frontmatter → 4. modèle de la conversation principale.

### Choix du modèle (guidage coût/capacité)
- `haiku` : rapide, peu coûteux → recherche/exploration, tâches volumineuses.
- `sonnet` : équilibre capacité/vitesse → revue de code, analyse.
- `opus` : le plus capable → raisonnement complexe, tâches critiques.
- `inherit` : aligne sur la conversation principale (défaut).

## 4. Principes de conception (Anthropic ∩ OpenAI)

Convergence des deux fournisseurs — colonne vertébrale du skill :

1. **Un subagent = une tâche focalisée.** « Design focused subagents : each
   subagent should excel at one specific task » (Anthropic). OpenAI : un agent =
   un LLM configuré avec *instructions + tools + handoffs/guardrails*.
2. **`description` (Anthropic) / rôle (OpenAI) = déclencheur.** Rédiger une
   description spécifique : c'est elle qui décide de la délégation. « Write
   detailed descriptions ». Ajouter « use proactively » si délégation proactive.
3. **Moindre privilège sur les outils.** « Limit tool access : grant only
   necessary permissions for security and focus » (Anthropic). OpenAI :
   `tool_choice`, garde-fous en couches (*layered defense*).
4. **Contexte isolé.** Le subagent part d'un contexte frais ; ne renvoie qu'un
   résumé. OpenAI : objets de contexte injectés explicitement, pas en dur.
5. **Sortie structurée.** OpenAI : `output_type` typé pour des résultats
   parseables. Côté CC : préciser dans le prompt système le format de retour.
6. **Délégation / handoff.** OpenAI : `handoffs` entre agents. CC : chaînage et
   sous-subagents imbriqués ; un subagent peut spawner des subagents si `Agent`
   est dans `tools`.
7. **Garde-fous & comportement « quand incertain ».** Instructions explicites,
   validation des entrées, hooks `PreToolUse` pour contraindre (ex. SQL read-only).
8. **Versionner les subagents projet** (`.claude/agents/`) pour partage d'équipe.

### Anatomie d'un prompt système de subagent (motif officiel)
Les exemples Anthropic (code-reviewer, debugger, data-scientist) suivent tous :
1. **Rôle** : « You are a senior … specialist. »
2. **Déclencheur / workflow** : « When invoked: 1… 2… 3… »
3. **Checklist / pratiques** ciblées du domaine.
4. **Format de sortie** : feedback organisé par priorité, exemples de fix.

## 5. Paramètres que `subagent-creator` doit exposer

Dérivés des champs réellement documentés. **Le modèle est exigé par
l'utilisateur** ; les autres sont classés requis / optionnel.

| Param | Statut | Mappe vers | Défaut |
|-------|--------|-----------|--------|
| `name` | **Requis** | `name` | — (kebab-case) |
| `description` (déclencheur) | **Requis** | `description` | — (inclure le « quand ») |
| `purpose` / contenu du prompt système | **Requis** | corps Markdown | — |
| **`model`** | **Requis (demande utilisateur)** | `model` | `inherit` ; valeurs `sonnet`/`opus`/`haiku`/`fable`/ID/`inherit` |
| `tools` (allowlist moindre privilège) | Optionnel | `tools` | hérite tout si omis |
| `disallowedTools` | Optionnel | `disallowedTools` | — |
| `permissionMode` | Optionnel | `permissionMode` | `default` |
| `scope` (projet/user) | Optionnel | emplacement fichier | `.claude/agents/` (projet) |
| Avancé : `skills`, `memory`, `color`, `maxTurns`, `isolation`, `hooks` | Optionnel | champs homonymes | — |

Le skill doit, pour chaque paramètre, fournir une **valeur par défaut sensée**,
**inférer** ce qui peut l'être (rôle, archetype, outils minimaux) et ne **bloquer
que** sur une ambiguïté critique — au minimum confirmer `name`, `description`,
`model`.

## 6. Sources

**Anthropic / Claude Code**
- [Create custom subagents — Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- [Define subagents programmatically — Agent SDK](https://code.claude.com/docs/en/agent-sdk/subagents)
- [Plugins reference — agents](https://code.claude.com/docs/en/plugins-reference)
- Context7 : `/websites/code_claude`

**OpenAI**
- [A practical guide to building agents — OpenAI](https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/)
- [Agents — OpenAI Agents SDK](https://openai.github.io/openai-agents-python/agents/)
- [Handoffs — OpenAI Agents SDK](https://openai.github.io/openai-agents-python/handoffs/)
- Context7 : `/openai/openai-agents-python`
