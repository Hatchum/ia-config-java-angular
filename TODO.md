# Mutualiser la configuration entre Claude Code et Codex — Architecture retenue

> Document de référence. Objectif : maintenir **une seule source de vérité** pour tout le
> contenu « intelligent » (instructions, skills, règles métier, outils) partagé entre
> **Claude Code** (Anthropic) et **Codex** (OpenAI), tout en générant proprement les
> réglages techniques propres à chaque outil.

---

## 1. Principe directeur

Il n'existe **aucun fichier unique physiquement partageable** entre les deux outils : leurs
réglages techniques utilisent des formats incompatibles **par conception** (JSON pour
`settings.json` côté Claude, TOML pour `config.toml` côté Codex, Starlark pour les `.rules`
de Codex). Chercher un « fichier magique » est une impasse.

La stratégie retenue sépare deux natures de configuration :

1. **Le contenu intelligent** — instructions, skills, workflows, règles métier, déclarations
   d'outils. C'est ~70–80 % de la config, et il se mutualise **totalement** via deux
   mécanismes natifs : l'**import `@AGENTS.md`** (instructions) et le **standard ouvert
   `SKILL.md` + liens symboliques** (skills).
2. **Les réglages techniques** — `settings.json`, `config.toml`, permissions, politique
   d'exécution, hooks, subagents. Ils ne peuvent pas partager un fichier, mais on évite la
   **duplication de connaissance** en maintenant **une source abstraite unique** (YAML) qui
   **génère** les deux projections.

Règle mentale : on partage **l'intention** ; les fichiers spécifiques à chaque IA deviennent
de simples **routeurs légers** vers cette intention.

---

## 2. Ce qui se mutualise vraiment vs ce qui reste spécifique

| Brique | Claude Code | Codex | Mutualisable ? |
|---|---|---|---|
| **Instructions / mémoire** | `CLAUDE.md` (`~/.claude/`, projet, `CLAUDE.local.md`) | `AGENTS.md` (`~/.codex/`, racine projet, par-dossier) | ✅ **Oui** — `AGENTS.md` = source unique ; `CLAUDE.md` l'importe via `@AGENTS.md` |
| **Skills** | `~/.claude/skills/<nom>/SKILL.md` et `.claude/skills/` | `~/.agents/skills/` et `<repo>/.agents/skills/` | ✅ **Oui** — même format `SKILL.md`, partagé par symlink |
| **Workflows / commandes** | commandes fusionnées dans les skills | « custom prompts » remplacés par les skills | ✅ **Oui** — à exprimer comme skills *(à confirmer selon versions installées)* |
| **Règles métier (markdown)** | `.claude/rules/*.md` (auto-chargées, scoping `paths:`) | pas d'équivalent direct → via `AGENTS.md` ou skills | ⚠️ **Partiel** — symlink côté Claude + référence dans `AGENTS.md` côté Codex |
| **Settings (modèle, env)** | `settings.json` (JSON) | `config.toml` (TOML) | ❌ **Non** — formats incompatibles → générés depuis une source abstraite |
| **Permissions / exécution** | `permissions.allow/deny/ask` dans `settings.json` | `.rules` **Starlark** dans `.codex/rules/` | ❌ **Non** — concepts ET formats différents (voir §3) |
| **Subagents** | `.claude/agents/*.md` | TOML (`[agents]` / fichiers TOML) | ❌ **Non** — modèles différents → générés |
| **MCP** | `.mcp.json` / `settings.json` (JSON) | `[mcp_servers]` dans `config.toml` (TOML) | ❌ **Non** — déclaré 2×, mais depuis une source générée |

---

## 3. ⚠️ Le piège « Rules » (faux ami absolu)

Le mot **« Rules »** ne désigne **pas** la même chose dans les deux outils. Ne jamais mapper
l'un sur l'autre :

- **`.claude/rules/*.md` (Claude Code)** = des **instructions de comportement** en markdown,
  qui guident l'agent (conventions, connaissances métier). Scoping conditionnel possible via
  le frontmatter `paths:`.
- **`.codex/rules/*.rules` (Codex)** = une **politique d'exécution en Starlark** qui filtre
  les **commandes autorisées / promptées / interdites** hors sandbox. C'est l'équivalent des
  **permissions** de Claude Code (`allow`/`deny`/`ask`), **pas** de ses règles d'instruction.

**Conséquence d'architecture :** les règles métier markdown se mutualisent (Claude via symlink,
Codex via référence dans `AGENTS.md`). La politique d'exécution, elle, reste **strictement
par-outil** et se range avec les permissions / réglages de sécurité.

---

## 4. Architecture retenue

On adopte l'approche la plus légère et la plus fidèle aux docs officielles : **un dossier
canonique unique** + **symlinks** pour ce qui peut l'être + **génération** pour le résiduel.

### 4.1 Layout par projet (versionnable dans git)

```
mon-projet/
├── AGENTS.md                 # ① SOURCE UNIQUE des instructions (lu nativement par Codex)
├── CLAUDE.md                 #    contient "@AGENTS.md" + éventuelles notes propres à Claude
│
├── .ai/                      # ② Dossier canonique partagé (la SEULE vraie copie)
│   ├── skills/               #    SKILL.md — workflows & connaissances réutilisables
│   │   ├── deploy/SKILL.md
│   │   └── code-review/SKILL.md
│   ├── rules/                #    règles métier en markdown (comportement)
│   │   └── testing.md
│   └── config/               #    source abstraite (YAML) pour le résiduel non partageable
│       ├── mcp.yaml          #      serveurs MCP (générera JSON + TOML)
│       ├── permissions.yaml  #      permissions Claude + politique d'exécution Codex
│       └── subagents.yaml    #      définitions de subagents (générera .md + TOML)
│
├── .claude/                  # ③ Côté Claude Code
│   ├── skills   -> ../.ai/skills    (symlink)
│   ├── rules    -> ../.ai/rules     (symlink)
│   ├── agents/                      (GÉNÉRÉ depuis .ai/config/subagents.yaml)
│   └── settings.json                (GÉNÉRÉ — JSON : permissions, hooks, env)
│
├── .agents/                  # ④ Côté Codex — skills (standard ouvert)
│   └── skills   -> ../.ai/skills    (symlink)
│
├── .codex/                   # ⑤ Côté Codex — config & sécurité
│   ├── config.toml                  (GÉNÉRÉ — TOML : [mcp_servers], [hooks], agents)
│   └── rules/                       (Starlark — politique d'exécution, SPÉCIFIQUE Codex)
│
└── .mcp.json                 # ⑥ MCP côté Claude (GÉNÉRÉ depuis .ai/config/mcp.yaml)
```

**Points clés du layout :**

- `AGENTS.md` est la **source** des instructions ; `CLAUDE.md` ne contient que `@AGENTS.md`
  (+ notes spécifiques Claude si besoin). Codex lit `AGENTS.md` nativement.
- `.ai/skills/` est l'**unique copie** des skills ; `.claude/skills` et `.agents/skills`
  ne sont que des **liens** vers elle.
- ⚠️ Attention au double emplacement Codex : les **skills** vivent dans `.agents/skills`,
  mais la **config** Codex (`config.toml`, `rules/`) vit dans `.codex/`. Ce ne sont pas le
  même dossier.
- Tous les fichiers **générés** portent un en-tête de garde (voir §6).

### 4.2 Layout global (niveau `$HOME`, valable pour tous vos projets)

```
~/ai-config/                  # Hub central unique
├── AGENTS.md                 # instructions globales (style, préférences perso)
├── skills/                   # skills perso réutilisables partout
│   └── commit/SKILL.md
└── config/                   # source abstraite globale (YAML)
    ├── mcp.yaml
    └── permissions.yaml
```

Branché ensuite dans les emplacements attendus :

- `~/.claude/skills`  → symlink vers `~/ai-config/skills`
- `~/.agents/skills`  → symlink vers `~/ai-config/skills`  *(voir vigilance §7 : découverte fragile)*
- `~/.claude/CLAUDE.md` → importe `@~/ai-config/AGENTS.md`
- `~/.codex/AGENTS.md` → symlink (ou copie générée) vers `~/ai-config/AGENTS.md`
- `~/.claude/settings.json` et `~/.codex/config.toml` → **générés** depuis `~/ai-config/config/`

---

## 5. Détail par brique

### Instructions — `AGENTS.md`
- Écrire **tout le contenu** dans `AGENTS.md`. Codex le lit nativement.
- Côté Claude, deux options officielles :
    - **import** : `@AGENTS.md` en tête de `CLAUDE.md` (recommandé, portable Windows), avec
      possibilité d'ajouter des consignes propres à Claude en dessous ;
    - **symlink pur** : `ln -s AGENTS.md CLAUDE.md` (évite la divergence, mais nécessite des
      droits sous Windows).
- **Concision obligatoire :**
    - Codex **tronque** `AGENTS.md` au-delà de `project_doc_max_bytes`. Ce seuil est
      **configurable** (l'exemple officiel le porte à 65536 octets), mais le défaut est bas :
      gardez le fichier ramassé.
    - L'import `@path` côté Claude **organise sans économiser de contexte** : les fichiers
      importés sont chargés au lancement. Importer un énorme `AGENTS.md` charge tout.
    - Bonne pratique partagée : **garder les instructions sous ~200 lignes**, les deux outils
      les relisent à chaque tour et le bruit dilue les règles importantes.
- Astuce Codex : `project_doc_fallback_filenames` permet de reconnaître d'autres noms de
  fichiers (`TEAM_GUIDE.md`, etc.) comme instructions, si besoin.

### Skills — le vrai gisement de mutualisation
- Tout workflow multi-étapes ou connaissance réutilisable devient un **skill** : c'est le
  **seul format strictement identique** des deux côtés (standard ouvert *Agent Skills*).
- Un `SKILL.md` minimal compatible des deux outils ne requiert que `name` et `description`
  en frontmatter YAML.
- ⚠️ Claude Code propose des champs de frontmatter **étendus** (`context: fork`,
  `allowed-tools`, `paths`, …) que **Codex ignore** : inoffensifs, mais le comportement
  « avancé » ne sera actif que sous Claude.
- Les deux outils **suivent la cible des liens symboliques** lors du scan des skills → un
  seul dossier `.ai/skills/` symliké dans `.claude/skills` et `.agents/skills`.
- Codex scanne `.agents/skills` depuis le répertoire courant jusqu'à la racine du dépôt, et
  charge aussi les emplacements utilisateur / admin / système. Sa liste de skills exposés est
  plafonnée (~2 % du contexte, ou ~8000 caractères) → descriptions concises et bien ciblées.
- Désactiver un skill sans le supprimer côté Codex : entrée `[[skills.config]]` avec
  `enabled = false` dans `~/.codex/config.toml`.

### Workflows / commandes
- Ne plus utiliser les anciens formats propriétaires : **un workflow = un skill = partagé
  automatiquement.** *(La fusion commandes→skills côté Claude et la dépréciation des custom
  prompts côté Codex vont dans ce sens ; à confirmer sur vos versions installées.)*

### Règles métier (comportement)
- Source : `.ai/rules/*.md`.
- Claude : symlink `.claude/rules -> ../.ai/rules` (auto-chargées, scoping `paths:` possible).
- Codex : pas de dossier équivalent → **référencer** ces règles depuis `AGENTS.md` pour que
  Codex les prenne en compte.
- ⚠️ Ne pas confondre avec les `.codex/rules/*.rules` Starlark (voir §3).

### Subagents
- Source abstraite : `.ai/config/subagents.yaml`.
- Génération **par outil**, car les modèles diffèrent :
    - Claude : `.claude/agents/<nom>.md` (prompt, outils, permissions).
    - Codex : TOML (`name`, `description`, `developer_instructions`, modèle, sandbox, MCP…).
- Pas de partage de fichier possible — seulement une source commune projetée.

### MCP (outils externes)
- Source abstraite : `.ai/config/mcp.yaml`.
- Génération : `.mcp.json` (Claude) **et** `[mcp_servers.<id>]` dans `config.toml` (Codex).
- ⚠️ Correction d'une erreur fréquente : il n'existe **pas** de `.mcp.json` global unique lu
  par les deux. Codex déclare ses serveurs en **TOML**. La mutualisation se fait au niveau de
  la **source**, pas du fichier.
- **Secrets hors dépôt** : tokens, clés API, endpoints privés via variables d'environnement,
  helpers, ou config locale non versionnée.

### Hooks
- Source : scripts partagés (lint, tests, sécurité, formatage) dans `.ai/` (ou
  `~/ai-config/hooks/` au global), invoqués par **chemin** des deux côtés.
- Les **événements se ressemblent** conceptuellement, mais les **schémas diffèrent** : ne pas
  tenter un fichier hook unique chargé directement par les deux.
    - Claude : hooks dans `settings.json`.
    - Codex : `hooks.json` ou `[hooks]` dans `config.toml`.
- → On partage les **scripts**, on génère le **câblage** par outil.

### Settings, permissions, politique d'exécution
- Aucun partage de fichier (JSON vs TOML vs Starlark).
- Source abstraite unique (`.ai/config/permissions.yaml`) → un petit générateur produit
  `settings.json` (permissions Claude + hooks) **et** la projection Codex (`config.toml` +
  `.codex/rules/` Starlark pour la politique d'exécution).

---

## 6. Mise en place (commandes)

### macOS / Linux

```bash
# ① CLAUDE.md importe AGENTS.md (portable, recommandé)
printf '@AGENTS.md\n\n## Spécifique Claude Code\n' > CLAUDE.md

# ② Dossier canonique + skills partagés dans les 2 outils
mkdir -p .ai/skills .ai/rules .ai/config
ln -s ../.ai/skills .claude/skills
ln -s ../.ai/skills .agents/skills

# ③ Règles markdown côté Claude (Codex les lira via AGENTS.md)
ln -s ../.ai/rules .claude/rules

# ④ Global ($HOME), une fois pour tous les projets
mkdir -p ~/ai-config/skills
ln -s ~/ai-config/skills ~/.claude/skills
ln -s ~/ai-config/skills ~/.agents/skills
ln -s ~/ai-config/AGENTS.md ~/.codex/AGENTS.md
printf '@~/ai-config/AGENTS.md\n' > ~/.claude/CLAUDE.md
```

### Windows
Un symlink exige les droits **Administrateur** ou le **mode développeur**. Préférer :
- **Instructions** : l'import `@AGENTS.md` dans `CLAUDE.md` (pas de symlink).
- **Skills / rules** : des **junctions** (`mklink /J`) ou des **copies générées** par script.

```powershell
# Import (pas de droits requis)
"@AGENTS.md`n`n## Spécifique Claude Code" | Out-File CLAUDE.md -Encoding utf8

# Junctions pour les dossiers (alternative au symlink)
cmd /c mklink /J .claude\skills ..\.ai\skills
cmd /c mklink /J .agents\skills ..\.ai\skills
cmd /c mklink /J .claude\rules  ..\.ai\rules
```

### Générateur (résiduel non partageable)
Un script (`sync` en `bash` ou `PowerShell`) prend en charge :
1. Valider les YAML de `.ai/config/`.
2. Générer `AGENTS.md` (si assemblé depuis des fragments) et mettre à jour `CLAUDE.md`.
3. Poser/rafraîchir les symlinks (ou junctions/copies sous Windows) des skills.
4. Générer `settings.json`, `.mcp.json`, `config.toml`, `.codex/rules/`.
5. **Refuser d'écraser** un fichier modifié manuellement si l'en-tête `GENERATED` manque.

En-tête à insérer dans **tout fichier généré** :

```
<!-- GENERATED FROM .ai/config — DO NOT EDIT DIRECTLY -->
```

---

## 7. Gouvernance & versioning

| Catégorie | Où | Exemples |
|---|---|---|
| **À versionner (projet)** | dans le repo | règles projet, skills projet, instructions projet, hooks non secrets |
| **Niveau utilisateur** | `~/ai-config/`, non partagé en équipe | préférences perso, style de réponse, modèles par défaut, chemins locaux |
| **Hors Git** | jamais commité | tokens, clés API, endpoints privés, config machine |
| **Généré** | reconstruit par script | tout ce qui traduit la source commune en format Claude ou Codex |

---

## 8. Pièges & points de vigilance (récapitulatif)

- **« Rules » est un faux ami** : Claude = comportement (markdown) ; Codex = politique
  d'exécution (Starlark). Voir §3.
- **`.mcp.json` global unique = faux** pour Codex (TOML). Mutualiser la **source**, pas le fichier.
- **Découverte des skills Codex fragile** : des utilisateurs rapportent que `~/.agents/skills`
  n'est plus toujours découvert ; certains guides citent `~/.codex/skills`. Se fier à
  `.agents/skills` (officiel) **et tester après installation** sur votre version. Redémarrer
  Codex si un skill n'apparaît pas.
- **Troncature `AGENTS.md`** : seuil `project_doc_max_bytes` configurable mais bas par défaut.
  Garder le fichier concis (< ~200 lignes).
- **Import `@path` ≠ économie de contexte** : les imports chargent au lancement.
- **Frontmatter avancé de skills ignoré par Codex** : `context:`, `allowed-tools`, `paths`…
  ne s'activent que sous Claude.
- **Symlinks sous Windows** : droits requis → préférer import + junctions/copies.
- **`PROJECT_CONTEXT.md` à éviter** : approche par fichier custom « à lire » (proposée par
  une des réponses) — moins fiable que l'import natif `@AGENTS.md`. Écarté ici.
- **Une tâche par session** : limiter la pollution de contexte (commune aux deux outils).

---

## 9. Annexe — Synthèse des points relevés par chaque IA

Pour ne rien perdre des trois analyses sources.

### Réponse « Codex »
- Pas de fichier magique : créer une **source de vérité neutre** + adaptateurs minces.
- Structure `~/ai-agent-config/` avec `common/` (instructions, skills, agents, mcp, hooks,
  workflows) et `adapters/{claude,codex}/`.
- Mapping concret par brique (instructions, rules, skills, subagents, MCP, hooks).
- **Script de sync** (PowerShell sous Windows) qui valide les YAML, génère `AGENTS.md`,
  `CLAUDE.md`, `config.toml`, `settings.json`, `.mcp.json`, et pose junctions/copies.
- En-tête `GENERATED ... DO NOT EDIT DIRECTLY`.
- Gouvernance : à versionner / niveau utilisateur / hors Git / à générer.
- Cœur de la solution : **standardiser skills + MCP, générer le reste.**
- *Retenu :* la séparation source/adaptateurs, le script de sync, l'en-tête de garde, la
  matrice de gouvernance. *Allégé :* on privilégie symlinks plutôt que tout générer.

### Réponse « Claude Code »
- Convergence vers deux standards : **`AGENTS.md`** (instructions) et **`SKILL.md`** (skills).
- Claude Code lit `CLAUDE.md` (pas `AGENTS.md`) → `CLAUDE.md` **importe** `@AGENTS.md`.
- ~70–80 % de la config se mutualise ; le reste reste par-outil.
- **Tableau** mutualisable / spécifique (repris en §2).
- Les deux outils **suivent les symlinks** → mécanisme central.
- Détails fins : troncature `AGENTS.md` (`project_doc_max_bytes`), frontmatter avancé ignoré
  par Codex, `import` qui n'économise pas de contexte, workflows = skills.
- Résiduel (settings/MCP/permissions/subagents) : **source abstraite unique → 2 formats.**
- *Retenu :* c'est l'ossature de l'architecture de ce document (la plus exacte).

### Réponse « Gemini »
- **Contexte universel** via un `PROJECT_CONTEXT.md` racine + redirection. *(Écarté : moins
  fiable que l'import natif `@AGENTS.md`.)*
- **Hub central** `~/ai-config-hub/` (`skills/`, `agents/`, `hooks/`) + symlinks vers
  `~/.claude/` — *idée retenue pour le global (§4.2).*
- Codex : pointer les profils d'agents via `config.toml`.
- **MCP** comme convergence d'écosystème — *idée juste, mais le `.mcp.json` global unique est
  une erreur pour Codex (corrigé en §5 / §8).*
- **Hooks** : scripts partagés référencés par **chemins absolus** des deux côtés — *retenu.*
- Conclusion : séparer « l'intention » (hub + contexte) des « moteurs » (les CLI), qui
  deviennent de simples routeurs — *principe conservé.*

---

## 10. Sources officielles

- Claude Code — mémoire / `CLAUDE.md` / imports : <https://code.claude.com/docs/en/memory>
- Claude Code — settings : <https://code.claude.com/docs/en/settings>
- Claude Code — skills : <https://code.claude.com/docs/en/skills>
- Claude Code — subagents : <https://code.claude.com/docs/en/sub-agents>
- Claude Code — hooks : <https://code.claude.com/docs/en/hooks>
- Codex — config : <https://developers.openai.com/codex/config-reference>
- Codex — config avancée : <https://developers.openai.com/codex/config-advanced>
- Codex — skills : <https://developers.openai.com/codex/skills>
- Codex — instructions `AGENTS.md` : <https://developers.openai.com/codex/guides/agents-md>
- Codex — rules (Starlark) : <https://developers.openai.com/codex/rules>
- Codex — subagents : <https://developers.openai.com/codex/subagents>
