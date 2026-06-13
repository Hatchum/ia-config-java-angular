# Serveurs MCP (optionnel)

Claude Code se connecte aux serveurs Model Context Protocol (MCP) via un
**`.mcp.json` à portée projet** à la racine du dépôt (versionné), ou en les
ajoutant avec `claude mcp add`. MCP est **optionnel** — le kit fonctionne sans.

Les serveurs MCP Filesystem / Git sont volontairement écartés : Claude Code les
couvre déjà nativement (outils fichiers + `git` via Bash). La vraie valeur ajoutée
vient du serveur de ton hébergeur de code (GitLab ou GitHub).

## Ce que livre le kit
Un **`.mcp.json`** versionné avec le **serveur MCP GitLab via la CLI `glab`**
(la CLI officielle de GitLab), en serveur stdio local :
```json
{
  "mcpServers": {
    "gitlab": {
      "command": "glab",
      "args": ["mcp", "serve"]
    }
  }
}
```
- **Prérequis :** installer la [CLI `glab`](https://gitlab.com/gitlab-org/cli) et
  s'authentifier une fois — `glab auth login` (pour une instance self-managed,
  cibler l'hôte : `glab auth login --hostname gitlab.company.com`). Fonctionne
  ensuite sur GitLab self-managed et gitlab.com avec ton identité/tes permissions
  GitLab existantes.
- **Expérimental :** `glab mcp serve` est marqué expérimental par GitLab et peut
  évoluer. Aucun abonnement GitLab Duo requis.
- Les serveurs à portée projet sont **soumis à approbation** : chaque membre
  approuve au premier usage (`claude mcp reset-project-choices` réinitialise).
- **Tu n'utilises pas GitLab / tu ne veux pas de MCP ?** Remplace par un des
  serveurs ci-dessous, ou supprime `.mcp.json`.

## Alternatives (documentées, non livrées)

### MCP GitLab Duo hébergé (HTTP + OAuth)
Serveur hébergé officiel ; **nécessite GitLab Duo** activé sur ton instance /
groupe de premier niveau (abonnement). Pas de PAT dans le fichier — auth en OAuth.
```bash
claude mcp add --transport http --scope project gitlab https://gitlab.example.com/api/v4/mcp
# puis lancer `claude`, taper /mcp, et compléter l'OAuth dans le navigateur
```
Équivalent `.mcp.json` (remplacer l'hôte, ou utiliser `https://gitlab.com/api/v4/mcp`) :
```json
{ "mcpServers": { "gitlab": { "type": "http", "url": "https://gitlab.example.com/api/v4/mcp" } } }
```

### MCP GitHub (HTTP)
Pour les projets hébergés sur GitHub. Le serveur distant est
`https://api.githubcopilot.com/mcp/`. S'authentifier en **OAuth** (lancer `claude`,
taper `/mcp`) ou via un **PAT** dans l'en-tête :
```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer ${GITHUB_TOKEN}" }
    }
  }
}
```
Avec un PAT, le définir dans l'environnement (le fichier ne contient que
`${GITHUB_TOKEN}`) :
```powershell
$env:GITHUB_TOKEN = "<your-token>"   # PowerShell
```
```cmd
set GITHUB_TOKEN=<your-token>        :: cmd
```

## Serveurs génériques utiles (optionnels)
Complémentaires au serveur de l'hébergeur : ils sont **additifs** (ils s'ajoutent
à la map `mcpServers`, à côté de `gitlab`, ils ne le remplacent pas).

### Context7 — docs de bibliothèques à jour
Fournit la documentation à jour des libs/frameworks. Clé API **optionnelle**
(gratuite sur context7.com/dashboard) pour des quotas plus élevés.
```bash
# distant (HTTP)
claude mcp add --transport http --scope project context7 https://mcp.context7.com/mcp
#   avec clé : ajouter  --header "CONTEXT7_API_KEY: ${CONTEXT7_API_KEY}"
# local (stdio)
claude mcp add --scope project context7 -- npx -y @upstash/context7-mcp
```
Entrée `.mcp.json` (distant) :
```json
{ "mcpServers": { "context7": { "type": "http", "url": "https://mcp.context7.com/mcp" } } }
```

### Exa — recherche web
Recherche web en temps réel via l'API Exa. **Nécessite** une clé `EXA_API_KEY`
(dashboard.exa.ai/api-keys).
```bash
# distant (HTTP)
claude mcp add --transport http --scope project exa https://mcp.exa.ai/mcp
# local (stdio), clé via variable d'environnement
claude mcp add --scope project exa -e EXA_API_KEY=${EXA_API_KEY} -- npx -y exa-mcp-server
```
Entrée `.mcp.json` (local, clé via env) :
```json
{ "mcpServers": { "exa": { "command": "npx", "args": ["-y", "exa-mcp-server"], "env": { "EXA_API_KEY": "${EXA_API_KEY}" } } } }
```

## Ajouter / gérer des serveurs
Laisser Claude Code écrire `.mcp.json` pour toi :
```bash
# serveur distant (HTTP), partagé avec l'équipe
claude mcp add --transport http --scope project <name> <url>
# serveur local (stdio)
claude mcp add --scope project <name> -- <command> <args...>
```
Portées : `local` (toi seul) · `project` (équipe, via `.mcp.json`) · `user` (tous
tes projets).

## Notes
- L'**expansion de variables** (`${VAR}`, `${VAR:-default}`) garde les chemins
  spécifiques à la machine et les secrets hors du fichier versionné.
- **Ne jamais committer de secret** — passer les tokens par l'environnement, pas
  en clair.

## Références
- MCP Claude Code : <https://code.claude.com/docs/en/mcp>
- Context7 (Upstash) : <https://github.com/upstash/context7>
- Exa MCP : <https://docs.exa.ai/examples/exa-mcp>
- `glab mcp` GitLab : <https://docs.gitlab.com/cli/mcp/>
- GitLab Duo + Claude Code : <https://about.gitlab.com/blog/claude-code-and-gitlab/>
- Serveur MCP GitHub : <https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp/set-up-the-github-mcp-server>
