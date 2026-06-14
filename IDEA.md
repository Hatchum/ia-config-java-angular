## (A integrer proprement)

# Idees
Separer les responsabilité de dev (documentation / code back / code front / code test / tests) dans des subagent ?
Creer des rules / skills / hooks dédié pour ces subagent ?
Creer un plan / workflow pour dev
Creer un plan / workflow pour debug / fix
Creer team pour dev

# MCP
Ajouter le MCP Exa pour le web search (Payant)
Ajouter le MCP Context7

# Plan
.claude/plan

# Rules (Regle d'utilisation)
.claude/rules 

# Skills
[Install Skills](https://www.skills.sh)

# Hooks
Ajouter des hook pour la validation de fichier (syntaxe TS, JAVA, etc)
Creer un skill (skill-hook-creator).

# Meta-prompting
Creer un skill (skill-prompt-creator) : Recherche sur internet les meilleures technique de prompting proposé par Anthropic, OpenAI, Google, etc, pour creer des prompts les plus optimisé à partir des informations entrées en parametre par l'utilisateur.

# Claude-memory
Creer un skill (skill-claude-memory) : Recherche sur internet toute la documentation officielle de Claude code concernant la façon de creer et d'optimiser les fichiers CLAUDE.md (claude memory files), les .claude/rules (règles modulaire), pour des projets Claude Code. Guide détaillé de la hierarchie des fichiers, structure du contenu, regles des path-scoped, best practices, et anti-pattern. Use when working with CLAUDE.md files, .claude/rules directories, setting up new projects, or improving Claude Code's context awareness.

# Subagent
Creer un skill (skill-subagent-creator)
Creer des sous agents : 
- agent-explore-docs : Recherche la documentation officielle concernant une librairie ou une fonctionnalité précise (via MCP - Context7 / Model : Haiku)
- agent-explore-code : Explore le code du projet
- agent-explore-web : Explore le web (via MCP - Exa, WebSearch, WebFetch / Model : Haiku)
- agent-code-java : diversifier par couche ?
- agent-code-angular : diversifier affichage / logique / service / route ?

# Workflow
Creer un skill (skill-workflow-creator) avec des étapes (dans un sous-repertoire) :
- E(xplore): use subagents explore 
- P(lan) 
- C(ode) 
- T(est) 

# Prompt Discovery 
Utilisation d'un workflow-debug (par exemple), avec des étapes dans un dossier, pour séparer chaque étape afin que l'ia soit obligé de lire chaque fichier 1 par 1, pour pouvoir réaliser le workflow dans son entiereté et de lui eviter trop de contexte à l'initialisation :
**What it does:**
1. **Analyze** : Reproduce error, identify root cause -> **ask if you have more context**
2. **Log Technique** (if needed): Add debug logs -> **user runs & shares output** -> analyse
3. **Find Solutions**: Research 2-3+ portential fixes with pros/cons
4. **Propose**: Present options -> **you choose which solution**
5. **Fix**: Implement solution with strategic logging
6. **Verify**: Multi-layer verification (Static -> Build -> Runtime)

**Key Principle**: Tests passing <> fix working. Always execute the actual code path.

**Log Technique**: When the error can't be reproduced, strategic debug logs are added. The user runs the app and shares the console output for analysis.

Steps : 
step O / init / Parse flags, setup state
step 1 / analyze / Reproduce error, form hypotheses, identify root cause (Avec plusieurs technique d'analyse de pointe)
step 1b / log instrumentation / *Optional*: Add debug logs, user runs & shares outpur
step 2 / find solutions / Reasearch 2-3+ solutions with pros/cons
step 3 / propose / Present solutions for user selection
step 4 / fix / Implement with strategic logging
step 5 / verify / Multi-layer verification (Static -> Build -> Runtime -> User)

Reference :
log technique / Log placement patterns, prefixes, security guideline

# Team
Ajouter le setting claude agent-team

---

# Optimisation Claude Code

## Conversation
/clear
/compact
/context : Utilisation des MCP
/mcp

Output (réponse de Claude Code trop verbeuse)

## Modeles
- Opus -> Architecture, structuration, réflexion profonde (Tache complexe / Raisonnement)
- sonnet -> Code, écrire, éxecuter (tache modérée / Execution)
- Haiku -> Rechercher, classer (Tache simple/rapide)

## CLAUDE.md optimise (essentiel)

## Cache
Activé par défaut
Cahce mort, declencheurs : 
- Changer de modele
- Ajouter un MCP
- Long délai > 5min

## Fichier en prompt
| 1x | 5x | 20x | 
|.txt, .md < | .pdf,.doc < | image, screenshot

## Utilisation des subagent
Isoler correctement la tache de l'agent (modification d'un seul fichier, recherche, etc) orchéstré par l'agent principale
Utilisation des team avec task ?

## Lsp 
### Java
brew install jdtls
claude plugin install jdtls-lsp@claude-plugins-official

### typescript
npm i -g typescript-language-server typescript
claude plugin install typescript-lsp@claude-plugins-official

### verify
claude plugin list

s x
---
