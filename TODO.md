# Codex

Oui. La bonne approche n’est pas de chercher un fichier magique commun à Claude Code et Codex, parce qu’il n’existe
  pas officiellement. Il faut créer une source de vérité neutre, puis exposer des adaptateurs minces vers Claude Code et
  Codex.

  Ce que disent les docs officielles

  - Claude Code sépare les scopes Managed, User, Project, Local, avec notamment ~/.claude/, .claude/, CLAUDE.md,
    .claude/settings.json, .claude/skills/, .claude/agents/, .mcp.json selon le type de config. Les règles projet
    peuvent vivre dans .claude/rules/, avec du paths frontmatter, et Claude supporte les imports dans CLAUDE.md via
    @path docs Claude settings (https://code.claude.com/docs/en/settings) docs Claude memory/rules
    (https://code.claude.com/docs/en/memory).

  - Codex utilise ~/.codex/config.toml, .codex/config.toml, AGENTS.md, .agents/skills, .codex/rules/, .codex/agents/,
    hooks dans hooks.json ou [hooks] TOML, et charge les configs projet seulement dans les projets approuvés docs Codex
    config (https://developers.openai.com/codex/config-reference) docs Codex advanced config
    (https://developers.openai.com/codex/config-advanced).

  - Les skills sont le meilleur point de convergence : Claude Code et Codex s’appuient tous les deux sur le standard
    Agent Skills avec un dossier contenant SKILL.md et éventuellement scripts/, references/, assets/ docs Claude skills
    (https://code.claude.com/docs/en/skills) docs Codex skills (https://developers.openai.com/codex/skills).

  - MCP est aussi un bon point commun : les deux supportent MCP pour connecter des outils externes docs Claude MCP
    (https://code.claude.com/docs/en/mcp) docs Codex customization MCP
    (https://developers.openai.com/codex/concepts/customization).

## Architecture recommandée
  Crée un dépôt unique, par exemple :

  ~/ai-agent-config/
    common/
      instructions/
        global.md
        engineering.md
        security.md
        review.md
      skills/
        commit/
          SKILL.md
          scripts/
          references/
        code-review/
          SKILL.md
      agents/
        reviewer.yaml
        explorer.yaml
      mcp/
        servers.yaml
      hooks/
        policies.yaml
        scripts/
      workflows/
        release.md
        incident-debug.md

    adapters/
      claude/
        CLAUDE.md
        settings.json
        rules/
        agents/
        skills/ -> links or generated copies
        mcp.json

      codex/
        AGENTS.md
        config.toml
        rules/
        agents/
        hooks.json

  Le principe : tu modifies seulement common/, puis un script sync génère ou met à jour les fichiers propres à chaque
  outil.

## Mapping concret

  - Instructions générales :
      - Source : common/instructions/*.md
      - Claude : CLAUDE.md peut importer avec @../common/instructions/global.md.
      - Codex : génère AGENTS.md, car Codex documente AGENTS.md mais pas un mécanisme d’import équivalent à @path.

  - Rules :
      - Source : common/instructions/rules/*.md ou common/rules/*.yaml
      - Claude : .claude/rules/*.md, avec paths: si règle conditionnelle.
      - Codex : .codex/rules/*.rules pour les règles d’exécution de commandes hors sandbox. Attention : ce ne sont pas
        les mêmes “rules” que Claude. Les règles Claude guident le comportement ; les règles Codex contrôlent surtout
        les commandes autorisées/promptées/interdites Codex rules (https://developers.openai.com/codex/rules).

  - Skills :
      - Source : common/skills/<skill>/SKILL.md
      - Codex : expose via .agents/skills ou skills.config dans config.toml.
      - Claude : expose via .claude/skills.
      - Ici, tu peux utiliser des liens symboliques/junctions Windows ou générer des copies contrôlées. Les liens sont
        plus propres, les copies générées sont plus portables.

  - Subagents :
      - Source : common/agents/*.yaml
      - Claude : génère .claude/agents/<name>.md.
      - Codex : génère .codex/agents/<name>.toml.
      - Les modèles sont différents : Claude décrit des subagents spécialisés avec prompt, outils, permissions ; Codex
        définit des agents TOML avec name, description, developer_instructions, modèle, sandbox, MCP, etc. Claude
        subagents (https://code.claude.com/docs/en/sub-agents) Codex subagents
        (https://developers.openai.com/codex/subagents).

  - MCP :
      - Source : common/mcp/servers.yaml
      - Claude : génère .mcp.json ou config MCP Claude.
      - Codex : génère [mcp_servers.<id>] dans config.toml.
      - Garde les secrets hors dépôt : variables d’environnement, helpers, ou config locale non versionnée.

  - Hooks :
      - Source : common/hooks/policies.yaml + scripts partagés.
      - Claude : génère hooks dans .claude/settings.json.
      - Codex : génère hooks.json ou [hooks] dans .codex/config.toml.
      - Les événements se ressemblent conceptuellement, mais les schémas ne sont pas identiques. Ne tente pas un fichier
        hook unique directement chargé par les deux Claude hooks (https://code.claude.com/docs/en/hooks) Codex config
        hooks (https://developers.openai.com/codex/config-advanced).

## Structure par projet
  Dans chaque repo applicatif, je ferais :

  my-project/
    AGENTS.md              # généré depuis common + règles projet
    CLAUDE.md              # petit fichier qui importe ou référence common
    .agents/
      skills/              # liens ou copies générées vers common/skills
    .codex/
      config.toml
      rules/
      hooks.json
      agents/
    .claude/
      settings.json
      rules/
      skills/
      agents/
    .mcp.json              # si MCP partagé côté Claude

  Ajoute un en-tête dans tous les fichiers générés :

  <!-- GENERATED FROM ~/ai-agent-config/common. DO NOT EDIT DIRECTLY. -->

## Stratégie pratique sur Windows
  Comme tu es sur Windows, le plus robuste est un script PowerShell :

  ~/ai-agent-config/tools/sync-agents.ps1 -TargetRepo C:\path\to\repo

  Il ferait :

  1. Valider les fichiers common/*.yaml.
  2. Générer AGENTS.md pour Codex.
  3. Générer ou mettre à jour CLAUDE.md.
  4. Copier ou créer des junctions pour les skills.
  5. Générer .codex/config.toml, .claude/settings.json, .mcp.json.
  6. Refuser d’écraser les fichiers modifiés manuellement si l’en-tête GENERATED manque.

  Décision importante
  Je te conseille cette règle de gouvernance :

  - À versionner dans les projets : règles projet, skills projet, instructions projet, hooks non secrets.
  - À garder au niveau utilisateur : préférences personnelles, style de réponse, modèles par défaut, chemins locaux.
  - À garder hors Git : tokens, clés API, endpoints privés, config machine.
  - À générer : tout ce qui traduit une source commune vers un format Claude ou Codex.

  Le cœur de la solution : standardiser les skills et MCP, générer le reste. C’est le seul modèle propre, durable, et
  compatible avec les docs officielles actuelles des deux outils.


# Claude Code 
Avant de plonger, il faut comprendre une chose qui change tout : Claude Code et Codex convergent désormais vers deux standards partagés que vous pouvez exploiter pour ne maintenir qu'une seule source de vérité.

- Pour les instructions : le standard AGENTS.md. La doc officielle de Claude Code est explicite : Claude Code lit CLAUDE.md, pas AGENTS.md ; si votre dépôt utilise déjà AGENTS.md pour d'autres agents, créez un CLAUDE.md qui l'importe pour que les deux outils lisent les mêmes instructions sans duplication. Codex, lui, lit AGENTS.md nativement. Claude
- Pour les skills/workflows : les deux outils suivent le même standard ouvert Agent Skills (agentskills.io) avec un format SKILL.md identique. Les skills de Claude Code suivent le standard ouvert Agent Skills, qui fonctionne sur plusieurs outils d'IA, et côté OpenAI, les skills de Codex s'appuient sur le même standard ouvert ; un skill est un répertoire avec un fichier SKILL.md plus des scripts et références optionnels. ClaudeOpenai
- Le point clé qui rend la mutualisation possible : les deux outils suivent les liens symboliques. C'est le mécanisme central de votre solution.

## Ce qui se partage vraiment vs ce qui reste spécifique
C'est le tableau le plus important. La réalité honnête : environ 70-80 % de votre config (le contenu « intelligent ») se mutualise totalement ; le reste (réglages techniques au format propriétaire) doit rester par-outil.
| Brique | Claude Code | Codex | Mutualisable ? |
|---|---|---|---|
| Instructions / mémoire | CLAUDE.md (~/.claude/, projet, CLAUDE.local.md) | AGENTS.md (~/.codex/AGENTS.md, racine projet, par-dossier) | ✅ Oui — AGENTS.md = source unique ; CLAUDE.md l'importe | 
| Skills | ~/.claude/skills/<nom>/SKILL.md et .claude/skills/ | ~/.agents/skills/ et <repo>/.agents/skills/ | ✅ Oui — même format SKILL.md, via symlink | 
| Workflows / commandes | .claude/commands/ → fusionnés dans les skills | « custom prompts » dépréciés → remplacés par les skills | ✅ Oui — à exprimer comme skills | 
| Rules (connaissance métier) | .claude/rules/*.md (auto-chargés, scoping par paths:) | pas d'équivalent direct → via AGENTS.md ou skills | ⚠️ Partiel — via symlink + référence dans AGENTS.md | 
| Settings (modèle, hooks, env) | settings.json (JSON) | config.toml (TOML) | ❌ Non — formats incompatibles | 
| Permissions / exécution | permissions.allow/deny dans settings.json | « Rules » = .rules en Starlark (~/.codex/rules/) | ❌ Non — concepts et formats différents | 
| Subagents | fichiers .claude/agents/*.md | section [agents] dans config.toml | ❌ Non — formats différents | 
| MCP | .mcp.json / settings.json (JSON) | [mcp_servers] dans config.toml (TOML) | ❌ Non — à déclarer 2×, mais depuis une source générée |

⚠️ Piège à éviter absolument : le mot « Rules » est un faux ami. Les « Rules » de Codex ne sont pas l'équivalent des .claude/rules/. Les Rules de Codex servent à contrôler quelles commandes Codex peut exécuter hors du sandbox (politique d'exécution en langage Starlark) — c'est l'équivalent des permissions de Claude Code, pas de ses règles d'instruction en markdown. openai

## L'architecture concrète recommandée
L'idée : un dossier canonique unique (.ai/) contenant le contenu partagé, et des symlinks qui le « branchent » dans les répertoires attendus par chaque outil. Voici le layout par projet (versionnable dans git) :
mon-projet/
├── AGENTS.md                  # ① SOURCE UNIQUE des instructions (lu nativement par Codex)
├── CLAUDE.md                  #    contient juste "@AGENTS.md" (+ notes spécifiques Claude)
│
├── .ai/                       # ② Dossier canonique partagé (la seule vraie copie)
│   ├── skills/                #    SKILL.md — workflows & connaissances réutilisables
│   │   ├── deploy/SKILL.md
│   │   └── api-conventions/SKILL.md
│   └── rules/                 #    règles métier en markdown (optionnel)
│       └── testing.md
│
├── .claude/                   # ③ Côté Claude Code
│   ├── skills  ->  ../.ai/skills     (symlink)
│   ├── rules   ->  ../.ai/rules      (symlink)
│   └── settings.json                 (spécifique Claude — JSON)
│
└── .agents/                   # ④ Côté Codex
    └── skills  ->  ../.ai/skills     (symlink)


Les commandes pour câbler ça (macOS / Linux) :
bash ① CLAUDE.md pointe vers AGENTS.md (option import, recommandée et portable Windows)
printf '@AGENTS.md\n\n## Spécifique Claude Code\n' > CLAUDE.md

② Branche le dossier skills canonique dans les 2 outils
mkdir -p .ai/skills .ai/rules
ln -s ../.ai/skills .claude/skills
ln -s ../.ai/skills .agents/skills

③ Branche les règles markdown côté Claude (Codex les lira via AGENTS.md)
ln -s ../.ai/rules .claude/rules


Pour la config globale (valable sur tous vos projets), même logique au niveau de votre $HOME :
bash# Un dossier maître unique pour tous vos skills perso
mkdir -p ~/ai-config/skills
ln -s ~/ai-config/skills ~/.claude/skills      # Claude Code (perso)
ln -s ~/ai-config/skills ~/.agents/skills      # Codex (perso)

Instructions globales : AGENTS.md global + CLAUDE.md qui l'importe
ln -s ~/ai-config/AGENTS.md ~/.codex/AGENTS.md
printf '@~/ai-config/AGENTS.md\n' > ~/.claude/CLAUDE.md


C'est confirmé côté officiel : Codex lit les skills depuis les emplacements dépôt, utilisateur, admin et système, et supporte les dossiers de skills en symlink en suivant la cible du lien. Et côté Claude Code, le répertoire .claude/rules/ supporte les symlinks, ce qui permet de maintenir un jeu de règles partagé et de le lier dans plusieurs projets.

## Le détail par brique
Instructions (AGENTS.md) — Écrivez tout dans AGENTS.md. Pour Claude, deux options officielles : l'import @AGENTS.md en tête du CLAUDE.md (vous pouvez ajouter des consignes propres à Claude en dessous), ou un symlink pur ln -s AGENTS.md CLAUDE.md. Sur Windows, créer un symlink exige les droits Administrateur ou le mode développeur, donc préférez l'import @AGENTS.md. Notez que Codex tronque AGENTS.md à 32768 octets par défaut (project_doc_max_bytes) embarqués dans les instructions du premier tour — gardez le fichier concis. ClaudeOpenai

Skills (le vrai gisement de mutualisation) — Tout ce qui est procédure multi-étapes ou connaissance réutilisable doit devenir un skill, car c'est le seul format strictement identique entre les deux. Un SKILL.md minimal compatible des deux côtés ne requiert que name et description en frontmatter YAML. Attention à un détail : Claude Code propose des champs de frontmatter étendus (context: fork, allowed-tools, paths, etc.) que Codex ignorera — ils restent inoffensifs, mais le comportement « avancé » ne sera actif que sous Claude.

Workflows / commandes — N'utilisez plus les anciens formats propriétaires. Codex marque désormais les custom prompts comme dépréciés et recommande les skills pour les instructions réutilisables, et côté Claude les commandes personnalisées ont été fusionnées dans les skills. Donc : un workflow = un skill = partagé automatiquement. AiopsschoolClaude

Settings, permissions, subagents, MCP — Ici, pas de partage de fichier possible (JSON vs TOML vs Starlark vs frontmatter). La bonne pratique « sans duplication conceptuelle » : maintenir une source unique abstraite (par ex. un fichier YAML décrivant vos serveurs MCP, vos permissions, vos subagents) et un petit script qui génère settings.json ET config.toml à partir d'elle. Vous ne dupliquez pas la connaissance, seulement sa projection dans deux formats.

## En résumé
Vous ne pourrez jamais avoir un seul fichier physique pour tout, parce que les réglages techniques utilisent des formats incompatibles par conception. Mais vous pouvez atteindre zéro duplication du contenu qui compte :

- AGENTS.md = source unique des instructions ; CLAUDE.md l'importe.
- Un dossier skills/ canonique unique, symliké dans .claude/skills et .agents/skills → couvre skills, workflows et la plupart des « règles ».
- Pour le résiduel divergent (settings/MCP/permissions/subagents), une source abstraite unique générant les deux formats.

Si vous voulez, je peux vous générer un script de bootstrap (setup.sh + son équivalent PowerShell pour Windows) qui crée toute cette arborescence, pose les symlinks et installe un générateur settings.json/config.toml à partir d'un YAML — vous n'auriez qu'à le lancer dans vos projets. Dites-moi sous quel OS vous travaillez principalement et si vous voulez la version « projet », « globale », ou les deux.


# Gemini 
Faire cohabiter Claude Code (Anthropic) et Codex (OpenAI) en appliquant le principe DRY (Don't Repeat Yourself) est une excellente initiative. Bien que ces deux CLI utilisent des formats et des chemins de configuration différents (fichiers JSON/MD pour Claude, fichiers TOML/MD pour Codex), il est tout à fait possible de centraliser votre logique métier, vos règles et vos agents pour qu'ils s'abreuvent à la même source.

Voici la stratégie architecturale pour unifier ces deux environnements à travers tous vos projets, basée sur les documentations officielles récentes des deux outils.

1. Le Contexte de Projet Universel (Project Scope)
Plutôt que d'écrire vos règles métier en double dans le CLAUDE.md (pour Anthropic) et dans les couches de configuration .codex/ (pour OpenAI), créez un fichier de vérité absolu à la racine de chaque projet.

L'approche : Créez un fichier PROJECT_CONTEXT.md à la racine. Ce fichier contiendra l'architecture, les conventions de code, le contexte métier et les workflows spécifiques au projet.

Pour Claude Code : Dans votre fichier CLAUDE.md, ne mettez qu'une instruction de redirection :

Markdown
# Contexte global
Lis impérativement le fichier `PROJECT_CONTEXT.md` pour comprendre les règles, l'architecture et les standards de ce projet avant de planifier la moindre tâche.
Pour OpenAI Codex : Dans votre fichier de configuration local (ou votre AGENTS.md si vous utilisez les agents par défaut du répertoire de travail), ajoutez une règle système similaire exigeant la lecture prioritaire du PROJECT_CONTEXT.md.

2. Le Hub Centralisé et les Liens Symboliques (Symlinks)
Pour partager les configurations globales (agents, "skills", paramètres persistants) entre vos différents projets et entre les deux IA, vous devez sortir la donnée des dossiers natifs (~/.claude/ et ~/.codex/) pour la placer dans un Hub central.

Créer le Hub : Créez un dossier global sur votre machine, par exemple ~/ai-config-hub/.

Plaintext
~/ai-config-hub/
├── skills/          # Vos workflows réutilisables (ex: deploy_checklist.md)
├── agents/          # Définitions de vos sous-agents spécialisés
└── hooks/           # Scripts d'automatisation exécutables (bash, python, node)
Lier Claude Code : Claude cherche ses agents et skills dans ~/.claude/agents/ et ~/.claude/skills/. Supprimez ces dossiers s'ils existent et créez des liens symboliques pour qu'ils pointent vers votre Hub :

Bash
ln -s ~/ai-config-hub/skills ~/.claude/skills
ln -s ~/ai-config-hub/agents ~/.claude/agents
Lier Codex : Codex permet de définir le chemin de configuration des agents via config.toml (par exemple agents.<name>.config_file). Configurez votre ~/.codex/config.toml global pour faire pointer tous les profils d'agents vers le dossier partagé ~/ai-config-hub/agents/.

3. Mutualisation des Outils via MCP (Model Context Protocol)
L'écosystème IA converge actuellement vers le standard MCP pour se connecter à des outils externes (GitHub, bases de données, Sentry, navigateurs headless). C'est le moyen le plus puissant d'éviter la duplication des outils techniques.

Ne configurez pas de petits scripts ou d'outils spécifiques en dur dans les settings isolés de Claude ou de Codex.

Gérez vos outils via un fichier global .mcp.json (ou configurez un serveur MCP local unique) et demandez aux deux CLI de s'y connecter. Ainsi, l'ajout d'une intégration externe (comme un accès direct à Jira ou Slack) profitera aux deux IA instantanément et avec les mêmes droits.

4. Harmonisation des Hooks (Scripts d'automatisation)
Les deux outils permettent de déclencher des "hooks" (scripts qui s'exécutent lors d'événements spécifiques, comme avant un commit, au lancement d'une session, ou lors d'une utilisation d'outil).

Stockez vos scripts de vérification (linting, tests de sécurité, formatage) dans ~/ai-config-hub/hooks/.

Dans ~/.claude/settings.json et dans le config.toml de Codex, référencez les chemins absolus vers ces mêmes scripts. La logique d'exécution restera la même quel que soit le modèle IA qui déclenche l'action.

En séparant "l'intention" (stockée dans votre Hub et votre contexte universel) des "moteurs" (Claude Code ou Codex Desktop/CLI), les fichiers de configuration spécifiques à chaque IA se transforment en simples routeurs très légers.

Souhaites-tu que je te génère un script Bash automatisé pour créer instantanément cette arborescence Hub et établir tous les liens symboliques vers les dossiers de Claude et de Codex sur ta machine ?
